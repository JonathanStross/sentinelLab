#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Azure Monitor Logs Ingestion API Sender
# Stream: Custom-Pathlock_TDnR
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
PRESET_STREAM="Custom-Pathlock_TDnR"

print_help() {
cat <<EOF
Azure Monitor Logs Ingestion Script (Custom-Pathlock_TDnR)

USAGE:
  ./Custom-Pathlock_TDnR.sh [options]

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
  -m <stream>        Stream name (default: Custom-Pathlock_TDnR)
  -f <file>          Path to external JSON file for payload
  -v                 Verbose output

EXAMPLE:
  ./Custom-Pathlock_TDnR.sh -t <tenant> -a <appId> -s <secret> \
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
      "TimeGenerated": "2026-02-05T23:00:42Z",
      "SYSID": "SYS1",
      "KEY_FIELD": "KEY1234567890",
      "MANDT": "800",
      "DATA_SOURCE": "PATHLOCK",
      "EVENTID": "EVT001",
      "EVENTID_LFDNR": "0000000001",
      "INSTANCE": "INSTANCE1",
      "HOSTNAME": "host1",
      "BNAME": "user1",
      "TCODE": "TC01",
      "REPORT": "RPT01",
      "OKCODE": "OK",
      "AREA": "AREA1",
      "SUBID": "SUB1",
      "AGR_NAME": "AGR1",
      "PROFN": "PROF1",
      "TERMINAL": "TERM1",
      "DATUM": "20260206",
      "ZEIT": "062512",
      "SRC_IP": "10.0.0.1",
      "DEST_IP": "10.0.0.2",
      "URI": "/api/path",
      "PGMID": "PGM1",
      "OBJECT": "OBJ1",
      "OBJ_NAME": "OBJNAME1",
      "LOG_LINE": "Sample log line for Pathlock TDnR.",
      "DATUM_UTC": "20260206",
      "ZEIT_UTC": "052512",
      "FORWARDED": "",
      "EXPORTED": "",
      "CONFIRMED": "",
      "RT_SYSID": "",
      "CONF_USER": "",
      "CONF_DATE": "00000000",
      "CONF_TIME": "000000",
      "CONF_CHG_USER": "",
      "CONF_CHG_DATE": "00000000",
      "CONF_CHG_TIME": "000000",
      "INCIDENT": "",
      "PUSH": "X",
      "BYTES": 123456,
      "AFFECTED_USER": "user2",
      "TABNAME": "TAB1",
      "FILTER_NO": "0000000001",
      "FILENAME": "file.txt",
      "AUDIT_ACTIONID": "ACT001",
      "MSG_TYPE": "INFO",
      "MSG_ID": "MSG001",
      "MSG_NO": "001",
      "MESSAGE_V1": "Value1",
      "MESSAGE_V2": "Value2",
      "MESSAGE_V3": "Value3",
      "MESSAGE_V4": "Value4",
      "CENTRAL_TS": "20260206052903.9079940 "
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
