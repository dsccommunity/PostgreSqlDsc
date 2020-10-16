# PostgreSqlDsc

DSC module to install and configure PostgreSQL on Windows

**Note**
This module is being actively developed and is not ready for production use.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Resources

- **PostgreSqlInstall**: Installs Postgres using the installer from EDB.

### PostgreSqlInstall

| Parameter | Attribute | DataType | Description | Default
| ---- | ---- | ---- | ---- | ---- |
| ServiceName | Key | String | Specifies the name of the Postgres service. | |
| Prefix | Write | String | Specifies the path for the install. | C:\\Program Files\\$ServiceName |
| Port | Write | UInt16 |Specifies the port of the service. | PostgreSql Default |
| DataDir | Write | String | Specifies the data directory inside the prefix. | Data |
| ServiceAccount | Write | PSCredential | Specifies the account used to run the service. | NT AUTHORITY\\NetworkService |
| Features | Write | String | Specifies the components to be installed. | server,pgAdmin,stackbuilder,commandlinetools |
