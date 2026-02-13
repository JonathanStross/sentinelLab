
# sentinelLab

This repository contains helper scripts and content for integrating and pushing data to Microsoft Sentinel and related Azure services.

## Project Structure

```
sentinelLab/
├── LICENSE
├── README.md                # (This file)
├── scripts/
│   └── push/
│       ├── sap_abapauditlog.sh         # Script for pushing SAP ABAP audit logs to Azure Monitor Logs
│       ├── Custom-Pathlock_TDnR.sh     # Script for pushing Pathlock TDnR data to Azure Monitor Logs
│       └── readme.md                   # Documentation for the push scripts
```

### scripts/push/
This folder contains all scripts and documentation for pushing data to Azure Monitor Logs (Sentinel) via the Logs Ingestion API. Each script is tailored for a specific data source or integration scenario:

- **sap_abapauditlog.sh**: For SAP ABAP audit log ingestion.
- **Custom-Pathlock_TDnR.sh**: For Pathlock TDnR data ingestion.
- **readme.md**: Detailed usage, setup, and deployment instructions for the scripts.


Refer to `scripts/push/readme.md` for detailed instructions on setup, usage, and deployment of each script and the required Sentinel data connectors.

---

For questions or improvements, see the script-level documentation or contact the repository owner.
