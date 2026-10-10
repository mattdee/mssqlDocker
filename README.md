# mssqlDocker

Manage a local Microsoft SQL Server container with one Bash script that works with Docker or Podman.

## Repository Contents

| File | Description |
| --- | --- |
| `sqlServerContainer.sh` | SQL Server container manager with CLI commands and an interactive menu. |
| `LICENSE` | Project license. |

## What The Script Does

`sqlServerContainer.sh` can:

- Start, stop, restart, and remove a SQL Server container
- Use Docker or Podman
- Auto-detect a working container engine
- Create a container network
- Create a named volume for SQL Server data
- Pull the configured SQL Server image
- Show container status, logs, and port mappings
- Open bash or root shell access inside the container
- Open an interactive `sqlcmd` session
- Run a quick `SELECT @@VERSION` test query
- Copy files into or out of the container

## Requirements

- Bash
- Docker or Podman
- Internet access to pull the SQL Server container image
- Enough local memory and disk for SQL Server

## Quick Start

Make the script executable:

```bash
chmod +x sqlServerContainer.sh
```

Start SQL Server:

```bash
./sqlServerContainer.sh start
```

Run a connection test:

```bash
./sqlServerContainer.sh test
```

Open `sqlcmd`:

```bash
./sqlServerContainer.sh sql
```

## CLI Commands

```bash
./sqlServerContainer.sh pull       # Pull the configured SQL Server image
./sqlServerContainer.sh start      # Start or restart the SQL Server container
./sqlServerContainer.sh stop       # Stop the running container
./sqlServerContainer.sh restart    # Restart the container
./sqlServerContainer.sh remove     # Remove the container
./sqlServerContainer.sh status     # Show container status, ports, and engine
./sqlServerContainer.sh logs       # Show container logs
./sqlServerContainer.sh bash       # Open bash in the container
./sqlServerContainer.sh root       # Open a root shell in the container
./sqlServerContainer.sh sql        # Open an interactive sqlcmd session
./sqlServerContainer.sh test       # Run SELECT @@VERSION
./sqlServerContainer.sh help       # Show help
```

Run without arguments to use the interactive menu:

```bash
./sqlServerContainer.sh
```

## Docker Or Podman

The script defaults to auto-detection:

```bash
CONTAINER_ENGINE=auto
```

In `auto` mode, the script uses Docker when Docker is installed and running. If Docker is not available, it uses Podman.

Force Docker:

```bash
CONTAINER_ENGINE=docker ./sqlServerContainer.sh start
```

Force Podman:

```bash
CONTAINER_ENGINE=podman ./sqlServerContainer.sh start
```

## Configuration

You can override these defaults with environment variables:

```bash
CONTAINER_ENGINE=auto
SQLSERVER_USER=sa
SQLSERVER_SA_PASS='M@tt1234!'
SQLSERVER_PID=Express
SQLSERVER_CONTAINER=SQLServer_DB_Container
SQLSERVER_VOLUME=sqlserver_data
SQLSERVER_NETWORK=sqlservernet
SQLSERVER_IMAGE=mcr.microsoft.com/mssql/server:2022-latest
CONTAINER_PORT_MAP='-p 1433:1433'
```

Examples:

```bash
SQLSERVER_SA_PASS='YourStrongPassword1!' ./sqlServerContainer.sh start
CONTAINER_PORT_MAP='-p 11433:1433' ./sqlServerContainer.sh start
SQLSERVER_CONTAINER=SQLServer_Dev ./sqlServerContainer.sh start
```

## SQL Server Image

The default image is:

```text
mcr.microsoft.com/mssql/server:2022-latest
```

To use another image:

```bash
SQLSERVER_IMAGE='mcr.microsoft.com/mssql/server:2022-latest' ./sqlServerContainer.sh start
```

The SQL Server 2025 RHEL image may fail on hosts that do not expose x86-64-v3 CPU features:

```text
Fatal glibc error: CPU does not support x86-64-v3
```

If your host supports that image, try:

```bash
SQLSERVER_IMAGE='mcr.microsoft.com/mssql/rhel/server:2025-latest' ./sqlServerContainer.sh start
```

## Data Persistence

The script creates a named volume and mounts it at SQL Server's data directory:

```text
sqlserver_data:/var/opt/mssql
```

Change the volume name with:

```bash
SQLSERVER_VOLUME=my_sqlserver_data ./sqlServerContainer.sh start
```

## sqlcmd Notes

The script checks for both common `sqlcmd` paths inside the container:

```text
/opt/mssql-tools18/bin/sqlcmd
/opt/mssql-tools/bin/sqlcmd
```

When it uses `mssql-tools18`, it adds `-C` to trust the local development certificate.

## Troubleshooting

Show container status:

```bash
./sqlServerContainer.sh status
```

Show SQL Server logs:

```bash
./sqlServerContainer.sh logs
```

If port `1433` is already in use, map another host port:

```bash
CONTAINER_PORT_MAP='-p 11433:1433' ./sqlServerContainer.sh start
```
