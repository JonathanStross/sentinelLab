### Script Permissions
Before running, ensure the script has execute permissions:

```bash
chmod +x sap_abapauditlog.sh
```



# SentinelLab Push Scripts

This directory contains scripts for pushing data to Azure Monitor Logs and other custom integrations. Each script is designed for a specific data source or integration scenario.

---

## Deploying the Pathlock_TDnR Sentinel Data Connector

To enable ingestion of Pathlock TDnR data into Microsoft Sentinel:

1. In the Azure Portal, go to your Microsoft Sentinel workspace.
2. Open the **Content hub** or **Data connectors** blade.
3. Search for **Pathlock_TDnR** in the store.
4. Select the connector and use the **Auto deploy** function to add it to your workspace.
5. Follow the on-screen instructions to complete the deployment and configuration.

---

---

## sap_abapauditlog.sh

**Purpose:**
Pushes SAP ABAP audit log data to Azure Monitor Logs using the Logs Ingestion API.

### Requirements
- `curl` and `jq` must be installed.
- Install on macOS:
	```bash
	brew install curl jq
	```
- Install on Linux (Debian/Ubuntu):
	```bash
	sudo apt-get update
	sudo apt-get install curl jq
	```
- Install on Linux (RHEL/CentOS):
	```bash
	sudo yum install curl jq
	```
- Install on Windows:
	- Use Windows Subsystem for Linux (WSL) and follow Linux instructions above.
	- Or download curl and jq binaries from their official websites.

### Usage
- Run with required parameters for Azure authentication and ingestion:
	```bash
	./sap_abapauditlog.sh -t <tenantId> -a <appId> -s <secret> \
		-e <dceHost> -d <dcrId>
	```
- Use `-p` to use preset placeholders (edit script to set values).
- Use `-f <file>` to send a custom payload from an external `.json` file:
	```bash
	./sap_abapauditlog.sh -t <tenantId> -a <appId> -s <secret> \
		-e <dceHost> -d <dcrId> -f /path/to/payload.json
	```
- Use `-h` for help and usage instructions.

### Setup
- Edit the script to set preset values if desired.
- Ensure you have valid Azure credentials and DCE/DCR information.

### Example
```bash
./sap_abapauditlog.sh -t <tenant> -a <appId> -s <secret> \
	-e xyz.germanywestcentral-1.ingest.monitor.azure.com -d <dcrId>
```

---


## Custom-Pathlock_TDnR.sh

**Purpose:**
Pushes Pathlock TDnR data to Azure Monitor Logs using the Logs Ingestion API and the Custom-Pathlock_TDnR stream.

### Requirements
- `curl` and `jq` must be installed (see above for installation instructions).

### Usage
- Make the script executable:
	```bash
	chmod +x Custom-Pathlock_TDnR.sh
	```
- Run with required parameters for Azure authentication and ingestion:
	```bash
	./Custom-Pathlock_TDnR.sh -t <tenantId> -a <appId> -s <secret> \
		-e <dceHost> -d <dcrId>
	```
- Use `-p` to use preset placeholders (edit script to set values).
- Use `-f <file>` to send a custom payload from an external `.json` file:
	```bash
	./Custom-Pathlock_TDnR.sh -t <tenantId> -a <appId> -s <secret> \
		-e <dceHost> -d <dcrId> -f /path/to/payload.json
	```
- Use `-h` for help and usage instructions.

### Setup
- Edit the script to set preset values if desired.
- Ensure you have valid Azure credentials and DCE/DCR information.

### Example
```bash
./Custom-Pathlock_TDnR.sh -t <tenant> -a <appId> -s <secret> \
	-e xyz.germanywestcentral-1.ingest.monitor.azure.com -d <dcrId>
```

### Sample Payload
The onboard payload in the script matches the following schema:

```json
[
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
]
```

---

For questions or improvements, see the main project README or contact the repository owner.
