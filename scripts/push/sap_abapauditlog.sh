#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Azure Monitor Logs Ingestion API Sender
# Stream: SAP_ABAPAUDITLOG
# ================================================================

API_VERSION="2023-01-01"
SCOPE="https://monitor.azure.com//.default"

# ----------------------------
# Placeholder Presets
# ----------------------------
PRESET_TENANT_ID="<TENANT_ID>"
PRESET_CLIENT_ID="<APPLICATION_ID>"
PRESET_CLIENT_SECRET="<APPLICATION_SECRET>"
PRESET_DCE_HOST="<DCE_INGEST_HOST>"   
PRESET_DCR_ID="<DCR_IMMUTABLE_ID>"
PRESET_STREAM="SAP_ABAPAUDITLOG"

print_help() {
cat <<EOF
Azure Monitor Logs Ingestion Script

USAGE:
  ./requests.sh [options]

OPTIONS:
  -h                 Show help
  -p                 Use preset placeholders (edit script first)
  -t <tenantId>      Entra Tenant ID
  -a <appId>         Entra Application (Client) ID
  -s <secret>        Entra Application Secret
  -e <dceHost>       Full DCE ingest host (NO https://)
                     Example:
                     xyz.germanywestcentral-1.ingest.monitor.azure.com
  -d <dcrId>         DCR immutable ID
  -m <stream>        Stream name (default: SAP_ABAPAUDITLOG)
  -f <file>          Path to external JSON file for payload
  -v                 Verbose output

EXAMPLE:
  ./requests.sh -t <tenant> -a <appId> -s <secret> \
                -e xyz.germanywestcentral-1.ingest.monitor.azure.com \
                -d <dcrId>
EOF
}

need() { command -v "$1" >/dev/null || { echo "Missing dependency: $1"; exit 1; }; }
need curl
need jq

USE_PRESET=0
VERBOSE=0

TENANT_ID=""
CLIENT_ID=""
CLIENT_SECRET=""
DCE_HOST=""
DCR_ID=""
STREAM="$PRESET_STREAM"

while getopts ":hpt:a:s:e:d:m:vf:" opt; do
  case "$opt" in
  h) print_help; exit 0 ;;
  p) USE_PRESET=1 ;;
  t) TENANT_ID="$OPTARG" ;;
  a) CLIENT_ID="$OPTARG" ;;
  s) CLIENT_SECRET="$OPTARG" ;;
  e) DCE_HOST="$OPTARG" ;;
  d) DCR_ID="$OPTARG" ;;
  m) STREAM="$OPTARG" ;;
  f) PAYLOAD_FILE="$OPTARG" ;;
  v) VERBOSE=1 ;;
  *) print_help; exit 2 ;;
  esac
done

# Apply preset placeholders
if [[ "$USE_PRESET" == "1" ]]; then
  TENANT_ID="${TENANT_ID:-$PRESET_TENANT_ID}"
  CLIENT_ID="${CLIENT_ID:-$PRESET_CLIENT_ID}"
  CLIENT_SECRET="${CLIENT_SECRET:-$PRESET_CLIENT_SECRET}"
  DCE_HOST="${DCE_HOST:-$PRESET_DCE_HOST}"
  DCR_ID="${DCR_ID:-$PRESET_DCR_ID}"
fi

# Validate required parameters
if [[ -z "$TENANT_ID" || -z "$CLIENT_ID" || -z "$CLIENT_SECRET" || -z "$DCE_HOST" || -z "$DCR_ID" ]]; then
  echo "ERROR: Missing required parameters."
  exit 1
fi

# -------------------------------------------------
# Payload Selection
# -------------------------------------------------
if [[ -n "${PAYLOAD_FILE:-}" ]]; then
  if [[ ! -f "$PAYLOAD_FILE" ]]; then
    echo "ERROR: Specified payload file '$PAYLOAD_FILE' does not exist."
    exit 1
  fi
  PAYLOAD=$(cat "$PAYLOAD_FILE")
else
  PAYLOAD='[
    {
      "AbapProgramName": "SAPMHTTP",
      "AgentId": "agent-001",
      "AlertSeverity": 100,
      "AlertSeverityText": "High",
      "AlertValue": 2,
      "AuditClassId": 10,
      "ClientId": "800",
      "Computer": "192.168.1.100",
      "Email": "user@example.com",
      "Host": "sap-server-01",
      "Instance": "sap-server-01_SID_00",
      "MessageClass": "MSGCL",
      "MessageContainerId": "container-123",
      "MessageId": "MSG001",
      "MessageText": "Example log message text.",
      "MonitoringObjectName": "MON_OBJ",
      "MonitorShortName": "MTE1",
      "RemoteIpCountry": "DE",
      "RemoteIpLatitude": 52.52,
      "RemoteIpLongitude": 13.405,
      "SalDateChar8": "20260206",
      "SalIpAddress": "2001:0db8:85a3:0000:0000:8a2e:0370:7334",
      "SalTimeChar6": "062512",
      "SapProcessType": "Dialog",
      "SapWorkProcessName": "WP01",
      "SourceSystem": "SAPPRD",
      "SystemId": "SID",
      "SystemNumber": "00",
      "SystemRole": "Production",
      "SystemUniqueId": "sys-unique-001",
      "TenantId": "57cdd3cf-ae8b-4672-aac8-72237a79b841",
      "TerminalIpV6": "2001:0db8:85a3:0000:0000:8a2e:0370:7334",
      "TimeGenerated": "2026-02-05T23:00:42Z",
      "TransactionCode": "SE80",
      "Type": "AUDIT_LOG",
      "UpdatedOn": "2026-02-05T23:00:42Z",
      "User": "SVOHRA",
      "Variable1": "Extra1",
      "Variable2": "Extra2",
      "Variable3": "Extra3",
      "Variable4": "Extra4"
    }
  ]'
fi

# -------------------------------------------------
# 1) Get OAuth Token
# -------------------------------------------------
TOKEN_RESPONSE=$(curl -sS -X POST \
  "https://login.microsoftonline.com/${TENANT_ID}/oauth2/v2.0/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "client_id=${CLIENT_ID}" \
  --data-urlencode "client_secret=${CLIENT_SECRET}" \
  --data-urlencode "grant_type=client_credentials" \
  --data-urlencode "scope=${SCOPE}"
)

ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | jq -r '.access_token')

if [[ -z "$ACCESS_TOKEN" || "$ACCESS_TOKEN" == "null" ]]; then
  echo "ERROR: Token request failed"
  echo "$TOKEN_RESPONSE" | jq .
  exit 1
fi

# -------------------------------------------------
# 2) Send to Logs Ingestion API
# -------------------------------------------------
INGEST_URL="https://${DCE_HOST}/dataCollectionRules/${DCR_ID}/streams/${STREAM}?api-version=${API_VERSION}"

echo "POST -> $INGEST_URL"

HTTP_STATUS=$(curl -sS -w "%{http_code}" \
  -X POST "$INGEST_URL" \
  -H "Authorization: Bearer ${ACCESS_TOKEN}" \
  -H "Content-Type: application/json" \
  --data "$PAYLOAD"
)

echo "HTTP Status: $HTTP_STATUS"

if [[ "$HTTP_STATUS" != "200" && "$HTTP_STATUS" != "202" && "$HTTP_STATUS" != "204" ]]; then
  echo "ERROR: Ingestion failed"
  exit 1
fi

echo "SUCCESS: Payload accepted"