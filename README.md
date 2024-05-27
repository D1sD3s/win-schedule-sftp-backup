# win-schedule-sftp-backup
## Usage
### Running the Script with Arguments

To run the script with direct arguments, use the following syntax:

```
.\backup-script.ps1 -ftpServer "yourserver.com:port" -ftpUsername "yourusername" -ftpPassword "yourpassword" [-ftpPath "/path/on/server"] [-localBackupDirectory "C:\path\to\backup"] [-maxBackups 5] [-winscpPath "C:\Path\To\WinSCP\WinSCP.com"]
```

- -ftpServer (required): The domain and port of the SFTP server.
- -ftpUsername (required): The username for the SFTP server.
- -ftpPassword (required): The password for the SFTP server.
- -ftpPath (optional): The path on the SFTP server to back up from. Default is /.
- -localBackupDirectory (optional): The local directory to save backups. Default is .\backup-data.
- -maxBackups (optional): The maximum number of backups to retain. Default is 5.
- -winscpPath (optional): The path to the WinSCP executable. Default is C:\Program Files (x86)\WinSCP\WinSCP.com.

### Running the Script with a Configuration File

You can also use a configuration file to provide all the necessary arguments. Create a config.json file in the script directory with the following structure:
```
{
    "ftpServer": "yourserver.com:port",
    "ftpUsername": "yourusername",
    "ftpPassword": "yourpassword",
    "ftpPath": "/path/on/server",
    "localBackupDirectory": "C:\\path\\to\\backup",
    "maxBackups": 5,
    "winscpPath": "C:\\Path\\To\\WinSCP\\WinSCP.com"
}
```
To run the script with the configuration file, use the following command:

```
.\backup-script.ps1 -config "path\to\config.json"
```
Important: When using the --config option, no other arguments should be provided.
