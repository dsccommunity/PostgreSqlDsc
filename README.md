# PostgreSqlDsc

DSC module to install and configure PostgreSQL on Windows

**Note**
This module is being actively developed and is not ready for production use.

## Code of Conduct

This project has adopted this [Code of Conduct](CODE_OF_CONDUCT.md).

## Resources

- **PostgreSqlInstall**: Installs Postgres using the installer from EDB.
- **PostgreSqlScript**: Allows scripts to be executed against PostgreSql databases using psql.exe.


### PostgreSqlInstall

| Parameter | Attribute | DataType | Description | Default
| ---- | ---- | ---- | ---- | ---- |
| Ensure | Key | String | "Absent" or "Present" only valid values | |
| Version | Required | String | "9", "10", "11", "12", or "13" only valid values | |
| InstallerPath | Required | String | File path to the exe installer from EDB | |
| ServiceName | Write | String | Specifies the name of the Postgres service. | |
| InstallDirectory | Write | String | Specifies the path for the install. | Postgres Default |
| ServerPort | Write | UInt16 | Specifies the port of the service. | PostgreSql Default |
| DataDirectory | Write | String | Specifies the data directory inside the prefix. | Postgres Default |
| ServiceAccount | Write | PSCredential | Specifies the account used to run the service. If builtin account is used password for credential does not matter. | Postgres Default |
| SuperAccount | Write | PSCredential | Specifies the account used as Super Admin for the Postgres Install | postgres / default  |
| Features | Write | String[] | Specifies the components to be installed. | Postgres Default |
| OptionFile | Write | String | Specifies the path of an option file for the installer. See Postgres Installer help for details | |

### PostgreSqlScript

| Parameter | Attribute | DataType | Description | Default
| ---- | ---- | ---- | ---- | ---- |
| DatabaseName | Key | String | Specifies the name of the _PostgreSQL_ database. | |
| SetFilePath | Key | String | Path to the T-SQL file that will perform _Set_ action | |
| GetFilePath | Key | String | Path to the T-SQL file that will perform _Get_ action | |
| SetFilePath | Key | String | Path to the T-SQL file that will perform _Test_ action | |
| Credential | Required | PsCredential | The credentials to authenticate with, using _Postgres Authentication_. | |
| PsqlLocation | Write | String | Location of the psql executable. | 'C:\Program Files\PostgreSQL\12\bin\psql.exe' Default |
| CreateDatabase | Write | Boolean |  | $true Default |
