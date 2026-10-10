# mssqlDocker

Utility scripts for running Microsoft SQL Server in local containers.

This repo now includes the original Docker and Podman scripts plus a newer combined manager that can use either container engine.

## Files

| File | Purpose |
| --- | --- |
| `sqlServerContainer.sh` | Current recommended script. Supports Docker or Podman, CLI commands, and an interactive menu. |
| `mssqlDocker.sh` | Original Docker-only SQL Server container script. |
| `mssqlPodman.sh` | Original Podman-only SQL Server container script. |
| `LICENSE` | Project license. |

## Recommended Script

Use `sqlServerContainer.sh` for new work:

```bash
./sqlServerContainer.sh start
```

Run it without arguments to open the interactive menu:

```bash
./sqlServerContainer.sh
```

## Commands

```bash
./sqlServerContainer.sh pull       # Pull the configured SQL Server image
./sqlServerContainer.sh start      # Start or restart the SQL Server container
./sqlServerContainer.sh stop       # Stop the running container
./sqlServerContainer.sh restart    # Restart the container
./sqlServerContainer.sh status     # Show container status and port mappings
./sqlServerContainer.sh logs       # Show SQL Server container logs
./sqlServerContainer.sh sql        # Open an interactive sqlcmd session
./sqlServerContainer.sh test       # Run SELECT @@VERSION
./sqlServerContainer.sh bash       # Open bash inside the container
./sqlServerContainer.sh root       # Open a root shell inside the container
./sqlServerContainer.sh remove     # Remove the SQL Server container
./sqlServerContainer.sh help       # Show help
```

## Docker or Podman

The combined script defaults to:

```bash
CONTAINER_ENGINE=auto
```

In auto mode, the script prefers Docker when Docker is installed and running. If Docker is not available, it falls back to Podman.

Force Docker:

```bash
CONTAINER_ENGINE=docker ./sqlServerContainer.sh start
```

Force Podman:

```bash
CONTAINER_ENGINE=podman ./sqlServerContainer.sh start
```

## Default Configuration

`sqlServerContainer.sh` can be configured with environment variables. Defaults are shown below:

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

Example override:

```bash
SQLSERVER_SA_PASS='YourStrongPassword1!' ./sqlServerContainer.sh start
```

Use a different image:

```bash
SQLSERVER_IMAGE='mcr.microsoft.com/mssql/server:2022-latest' ./sqlServerContainer.sh start
```

Use a different host port:

```bash
CONTAINER_PORT_MAP='-p 11433:1433' ./sqlServerContainer.sh start
```

## SQL Server Image Notes

The recommended default image is:

```text
mcr.microsoft.com/mssql/server:2022-latest
```

The SQL Server 2025 RHEL image can fail on some hosts with:

```text
Fatal glibc error: CPU does not support x86-64-v3
```

If your machine supports that image, you can try it with:

```bash
SQLSERVER_IMAGE='mcr.microsoft.com/mssql/rhel/server:2025-latest' ./sqlServerContainer.sh start
```

## Connecting

Open `sqlcmd` inside the container:

```bash
./sqlServerContainer.sh sql
```

Run a quick connection test:

```bash
./sqlServerContainer.sh test
```

The combined script checks for both common `sqlcmd` locations:

```text
/opt/mssql-tools18/bin/sqlcmd
/opt/mssql-tools/bin/sqlcmd
```

When using `mssql-tools18`, the script adds `-C` for local certificate trust.

## Legacy Scripts

The legacy scripts remain available:

```bash
./mssqlDocker.sh
./mssqlPodman.sh
```

Use these if you specifically want the older Docker-only or Podman-only flow. For most use cases, prefer `sqlServerContainer.sh`.
