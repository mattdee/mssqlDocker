# mssqlDocker

Shell scripts for managing Microsoft SQL Server containers.

## Scripts

- `mssqlDocker.sh` - original Docker-only manager
- `mssqlPodman.sh` - original Podman-only manager
- `sqlServerContainer.sh` - combined Docker/Podman manager

## Combined Docker/Podman Script

`sqlServerContainer.sh` supports both Docker and Podman with CLI commands and an interactive menu.

```bash
./sqlServerContainer.sh start      # Start or restart SQL Server
./sqlServerContainer.sh stop       # Stop SQL Server
./sqlServerContainer.sh restart    # Restart SQL Server
./sqlServerContainer.sh status     # Show container status and ports
./sqlServerContainer.sh logs       # Show container logs
./sqlServerContainer.sh sql        # Open sqlcmd
./sqlServerContainer.sh test       # Run SELECT @@VERSION
./sqlServerContainer.sh bash       # Open bash in the container
./sqlServerContainer.sh root       # Open root shell in the container
./sqlServerContainer.sh remove     # Remove the container
./sqlServerContainer.sh help       # Show help
```

Run without arguments for the interactive menu:

```bash
./sqlServerContainer.sh
```

## Docker or Podman

By default, `sqlServerContainer.sh` uses `CONTAINER_ENGINE=auto`, which prefers Docker when Docker is running and falls back to Podman.

Force Docker:

```bash
CONTAINER_ENGINE=docker ./sqlServerContainer.sh start
```

Force Podman:

```bash
CONTAINER_ENGINE=podman ./sqlServerContainer.sh start
```

## Configuration

The combined script can be configured with environment variables:

```bash
SQLSERVER_SA_PASS='YourStrongPassword1!' ./sqlServerContainer.sh start
SQLSERVER_IMAGE='mcr.microsoft.com/mssql/server:2022-latest' ./sqlServerContainer.sh start
SQLSERVER_PID='Express' ./sqlServerContainer.sh start
```

The default image is:

```text
mcr.microsoft.com/mssql/server:2022-latest
```

The SQL Server 2025 RHEL image may fail on hosts that do not expose x86-64-v3 CPU features.
