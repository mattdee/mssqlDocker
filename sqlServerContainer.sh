#!/bin/bash
#
#
   #===================================================================================
   #
   #         FILE: sqlServerContainer.sh
   #
   #        USAGE: ./sqlServerContainer.sh [start|stop|restart|bash|root|sql|status|logs|pull|remove|help]
   #
   #  DESCRIPTION: SQL Server container management script for Docker or Podman
   #      OPTIONS: See menu or command line arguments
   # REQUIREMENTS: Docker or Podman, internet connection
   #       AUTHOR: Matt D
   #      CREATED: 10.10.2026
   #      VERSION: 1.0
   #
   #===================================================================================

# Global variables
CONTAINER_ENGINE="${CONTAINER_ENGINE:-auto}"        # auto, docker, or podman
SQLSERVER_USER="${SQLSERVER_USER:-sa}"
SQLSERVER_SA_PASS="${SQLSERVER_SA_PASS:-M@tt1234!}"
SQLSERVER_PID="${SQLSERVER_PID:-Express}"
SQLSERVER_CONTAINER="${SQLSERVER_CONTAINER:-SQLServer_DB_Container}"
SQLSERVER_VOLUME="${SQLSERVER_VOLUME:-sqlserver_data}"
SQLSERVER_NETWORK="${SQLSERVER_NETWORK:-sqlservernet}"
SQLSERVER_IMAGE="${SQLSERVER_IMAGE:-mcr.microsoft.com/mssql/server:2022-latest}"
CONTAINER_PORT_MAP="${CONTAINER_PORT_MAP:--p 1433:1433}"
MAX_INVALID=3
INVALID_COUNT=0

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

#===========================
# Helper Functions
#===========================

logInfo() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

logWarning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

logError() {
    echo -e "${RED}[ERROR]${NC} $1"
}

logSuccess() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

displayMenu() {
    clear
    echo -e "${CYAN}===========================================================================${NC}"
    echo -e "${CYAN}             SQL Server Container Management Script                         ${NC}"
    echo -e "${CYAN}===========================================================================${NC}"

    echo -e "\n${GREEN}Container Management:${NC}"
    echo "  1) Start SQL Server container       6) Pull SQL Server image"
    echo "  2) Stop SQL Server container        7) Show container status"
    echo "  3) Bash access                      8) Show container logs"
    echo "  4) Root access                      9) Clean unused volumes"
    echo "  5) Remove SQL Server container      10) Exit script"

    echo -e "\n${GREEN}Database Access & Utilities:${NC}"
    echo "  11) sqlcmd user connection          13) Copy file into container"
    echo "  12) Run test query                  14) Copy file out of container"

    echo -e "\n${CYAN}===========================================================================${NC}"
    read -p "Please enter your choice [1-14]: " menuChoice
    export menuChoice=$menuChoice
}

resolveEngine() {
    if [ "$CONTAINER_ENGINE" = "auto" ]; then
        if command -v docker > /dev/null 2>&1 && docker ps > /dev/null 2>&1; then
            CONTAINER_ENGINE="docker"
        elif command -v podman > /dev/null 2>&1; then
            CONTAINER_ENGINE="podman"
        else
            logError "Neither Docker nor Podman is installed and available."
            exit 1
        fi
    fi
}

checkContainerEngine() {
    resolveEngine

    if ! command -v "$CONTAINER_ENGINE" > /dev/null 2>&1; then
        logError "$CONTAINER_ENGINE is not installed on your system."
        exit 1
    fi

    if [ "$CONTAINER_ENGINE" = "podman" ]; then
        if ! podman ps > /dev/null 2>&1; then
            logInfo "Podman is installed but not running. Starting Podman machine..."
            podman machine start
        fi
    elif ! docker ps > /dev/null 2>&1; then
        logError "Docker is installed but the Docker daemon is not available."
        logWarning "Start Docker Desktop or set CONTAINER_ENGINE=podman to use Podman."
        exit 1
    fi
}

createContainerNetwork() {
    checkContainerEngine

    if ! "$CONTAINER_ENGINE" network inspect "$SQLSERVER_NETWORK" > /dev/null 2>&1; then
        logInfo "Creating $CONTAINER_ENGINE network '$SQLSERVER_NETWORK'..."
        "$CONTAINER_ENGINE" network create -d bridge "$SQLSERVER_NETWORK"
    fi
}

getContainerId() {
    "$CONTAINER_ENGINE" ps --no-trunc --format "{{.Names}}" | grep -i "^${SQLSERVER_CONTAINER}$"
}

getContainerPresent() {
    "$CONTAINER_ENGINE" ps -a --no-trunc --format "{{.Names}}" | grep -i "^${SQLSERVER_CONTAINER}$"
}

countDown() {
    message=${1:-"Please wait..."}
    seconds=${2:-5}

    logInfo "$message"
    for (( i=$seconds; i>=1; i-- )); do
        echo -ne "\rStarting in $i seconds..."
        sleep 1
    done
    echo -e "\rStarting now!                  "
}

badChoice() {
    ((INVALID_COUNT++))

    logWarning "Invalid choice, please try again..."
    logWarning "Attempt $INVALID_COUNT of $MAX_INVALID."

    if [ "$INVALID_COUNT" -ge "$MAX_INVALID" ]; then
        logError "Too many invalid attempts. Exiting the script..."
        exit 1
    fi

    sleep 2
}

waitForSqlServer() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    logInfo "Waiting for SQL Server to accept connections..."
    for i in {1..30}; do
        if runSqlQuery "SELECT 1" > /dev/null 2>&1; then
            logSuccess "SQL Server is ready."
            return 0
        fi
        echo -ne "\rAttempt $i of 30..."
        sleep 5
    done

    echo
    logError "SQL Server did not become ready in time."
    logWarning "Use '$0 logs' to inspect container startup output."
    return 1
}

sqlcmdPath() {
    sqlContainer=$(getContainerId)

    if "$CONTAINER_ENGINE" exec "$sqlContainer" test -x /opt/mssql-tools18/bin/sqlcmd > /dev/null 2>&1; then
        echo "/opt/mssql-tools18/bin/sqlcmd"
    elif "$CONTAINER_ENGINE" exec "$sqlContainer" test -x /opt/mssql-tools/bin/sqlcmd > /dev/null 2>&1; then
        echo "/opt/mssql-tools/bin/sqlcmd"
    else
        echo ""
    fi
}

runSqlQuery() {
    query="$1"
    sqlContainer=$(getContainerId)
    sqlcmd=$(sqlcmdPath)

    if [ -z "$sqlcmd" ]; then
        logError "sqlcmd was not found in the container."
        return 1
    fi

    if [[ "$sqlcmd" == *"mssql-tools18"* ]]; then
        "$CONTAINER_ENGINE" exec "$sqlContainer" "$sqlcmd" -S localhost -U "$SQLSERVER_USER" -P "$SQLSERVER_SA_PASS" -C -Q "$query"
    else
        "$CONTAINER_ENGINE" exec "$sqlContainer" "$sqlcmd" -S localhost -U "$SQLSERVER_USER" -P "$SQLSERVER_SA_PASS" -Q "$query"
    fi
}

#===========================
# Core Functions
#===========================

doNothing() {
    logWarning "You want to quit...yes?"
    read -p "Enter yes or no: " doWhat
    if [[ $doWhat = yes ]]; then
        echo "Bye! ¯\\_(ツ)_/¯"
        exit 0
    else
        return
    fi
}

pullImage() {
    checkContainerEngine
    logInfo "Pulling SQL Server image: $SQLSERVER_IMAGE"
    "$CONTAINER_ENGINE" pull "$SQLSERVER_IMAGE"
}

listPorts() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -n "$sqlContainer" ]; then
        logInfo "Container ports:"
        "$CONTAINER_ENGINE" port "$sqlContainer"
    else
        logError "No running SQL Server container found."
    fi
}

showStatus() {
    checkContainerEngine
    logInfo "Using container engine: $CONTAINER_ENGINE"
    "$CONTAINER_ENGINE" ps -a --filter "name=$SQLSERVER_CONTAINER"
    listPorts
}

showLogs() {
    checkContainerEngine
    sqlPresent=$(getContainerPresent)

    if [ -z "$sqlPresent" ]; then
        logError "SQL Server container was not found."
        return 1
    fi

    "$CONTAINER_ENGINE" logs "$SQLSERVER_CONTAINER"
}

startSqlServer() {
    checkContainerEngine
    createContainerNetwork

    sqlRunning=$(getContainerId)
    sqlPresent=$(getContainerPresent)

    if [ "$sqlRunning" = "$SQLSERVER_CONTAINER" ]; then
        logWarning "SQL Server $CONTAINER_ENGINE container is already running."
        listPorts
        return
    elif [ "$sqlPresent" = "$SQLSERVER_CONTAINER" ]; then
        logInfo "SQL Server $CONTAINER_ENGINE container found, restarting..."
        "$CONTAINER_ENGINE" restart "$SQLSERVER_CONTAINER"
        waitForSqlServer
    else
        logInfo "Provisioning new SQL Server container with image: $SQLSERVER_IMAGE"
        "$CONTAINER_ENGINE" volume create "$SQLSERVER_VOLUME" > /dev/null
        "$CONTAINER_ENGINE" run -d \
            --name "$SQLSERVER_CONTAINER" \
            --network "$SQLSERVER_NETWORK" \
            $CONTAINER_PORT_MAP \
            -e "ACCEPT_EULA=Y" \
            -e "MSSQL_SA_PASSWORD=$SQLSERVER_SA_PASS" \
            -e "SA_PASSWORD=$SQLSERVER_SA_PASS" \
            -e "MSSQL_PID=$SQLSERVER_PID" \
            -v "$SQLSERVER_VOLUME:/var/opt/mssql" \
            "$SQLSERVER_IMAGE"

        if [ $? -ne 0 ]; then
            logError "Failed to start SQL Server container."
            logWarning "If you used the 2025 RHEL image and see 'CPU does not support x86-64-v3', set SQLSERVER_IMAGE='mcr.microsoft.com/mssql/server:2022-latest'."
            return 1
        fi

        logSuccess "SQL Server container started successfully."
        waitForSqlServer
    fi

    listPorts
}

stopSqlServer() {
    checkContainerEngine
    sqlRunning=$(getContainerId)

    if [ -z "$sqlRunning" ]; then
        logWarning "No SQL Server containers are running."
        return
    fi

    logInfo "Stopping container: $SQLSERVER_CONTAINER"
    "$CONTAINER_ENGINE" stop "$SQLSERVER_CONTAINER"
    if [ $? -eq 0 ]; then
        logSuccess "Container stopped successfully."
    else
        logError "Failed to stop container."
    fi
}

cleanVolumes() {
    checkContainerEngine
    logInfo "Cleaning unused volumes..."
    "$CONTAINER_ENGINE" volume prune -f
    logSuccess "Volumes cleaned."
}

removeContainer() {
    checkContainerEngine
    sqlPresent=$(getContainerPresent)

    if [ -z "$sqlPresent" ]; then
        logWarning "SQL Server container was not found."
        return
    fi

    stopSqlServer
    logInfo "Removing SQL Server container..."
    "$CONTAINER_ENGINE" rm "$SQLSERVER_CONTAINER"
    if [ $? -eq 0 ]; then
        logSuccess "Container removed successfully."
    else
        logError "Failed to remove container."
    fi
}

bashAccess() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    logInfo "Opening bash shell in container..."
    "$CONTAINER_ENGINE" exec -it "$sqlContainer" /bin/bash
}

rootAccess() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    logInfo "Opening root shell in container..."
    "$CONTAINER_ENGINE" exec -it -u 0 "$sqlContainer" /bin/bash
}

sqlCmdUser() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    sqlcmd=$(sqlcmdPath)
    if [ -z "$sqlcmd" ]; then
        logError "sqlcmd was not found in the container."
        return 1
    fi

    logInfo "Opening sqlcmd session as $SQLSERVER_USER..."
    if [[ "$sqlcmd" == *"mssql-tools18"* ]]; then
        "$CONTAINER_ENGINE" exec -it "$sqlContainer" "$sqlcmd" -S localhost -U "$SQLSERVER_USER" -P "$SQLSERVER_SA_PASS" -C
    else
        "$CONTAINER_ENGINE" exec -it "$sqlContainer" "$sqlcmd" -S localhost -U "$SQLSERVER_USER" -P "$SQLSERVER_SA_PASS"
    fi
}

testQuery() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    logInfo "Running SQL Server version query..."
    runSqlQuery "SELECT @@VERSION"
}

copyIn() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    read -p "Please enter the ABSOLUTE PATH to the file you want copied: " thePath
    read -p "Please enter the FILE NAME you want copied: " theFile

    logInfo "Copying file: $thePath/$theFile into container..."
    "$CONTAINER_ENGINE" cp "$thePath/$theFile" "$sqlContainer:/tmp"

    if [ $? -eq 0 ]; then
        logSuccess "File copied successfully to /tmp/$theFile in the container."
    else
        logError "Failed to copy file into container."
    fi
}

copyOut() {
    checkContainerEngine
    sqlContainer=$(getContainerId)

    if [ -z "$sqlContainer" ]; then
        logError "SQL Server container is not running."
        return 1
    fi

    read -p "Please enter the ABSOLUTE PATH in the CONTAINER to the file you want copied to host: " thePath
    read -p "Please enter the FILE NAME in the CONTAINER you want copied: " theFile

    logInfo "Copying file: $sqlContainer:$thePath/$theFile to host..."
    "$CONTAINER_ENGINE" cp "$sqlContainer:$thePath/$theFile" /tmp/

    if [ $? -eq 0 ]; then
        logSuccess "File copied successfully to /tmp/$theFile on your host."
    else
        logError "Failed to copy file from container."
    fi
}

showHelp() {
    echo -e "${BLUE}===========================================================================${NC}"
    echo -e "${BLUE}             SQL Server Container Management Script                         ${NC}"
    echo -e "${BLUE}===========================================================================${NC}"
    echo
    echo "Usage: $0 [command]"
    echo
    echo "Container engine:"
    echo "  CONTAINER_ENGINE=auto    # Default. Prefer Docker if running, otherwise Podman."
    echo "  CONTAINER_ENGINE=docker  # Force Docker."
    echo "  CONTAINER_ENGINE=podman  # Force Podman."
    echo
    echo "Container Management Commands:"
    echo "  start    - Start SQL Server container"
    echo "  stop     - Stop SQL Server container"
    echo "  restart  - Restart SQL Server container"
    echo "  remove   - Remove SQL Server container"
    echo "  status   - Show container status, ports, and engine"
    echo "  logs     - Show container logs"
    echo "  pull     - Pull SQL Server image"
    echo "  bash     - Bash access to container"
    echo "  root     - Root access to container"
    echo
    echo "Database Access Commands:"
    echo "  sql      - sqlcmd user connection"
    echo "  test     - Run SELECT @@VERSION"
    echo "  help     - Show this help message"
    echo
    echo "Configuration:"
    echo "  Override SQLSERVER_SA_PASS, SQLSERVER_IMAGE, SQLSERVER_PID,"
    echo "  SQLSERVER_CONTAINER, SQLSERVER_VOLUME, SQLSERVER_NETWORK, and CONTAINER_PORT_MAP."
    echo
    echo "If no command is provided, the script will start in interactive menu mode."
    echo -e "${BLUE}===========================================================================${NC}"
}

#===========================
# Main Program
#===========================

case "$1" in
    "start")
        logInfo "Starting container..."
        startSqlServer
        exit 0
        ;;
    "stop")
        logInfo "Stopping container..."
        stopSqlServer
        exit 0
        ;;
    "restart")
        logInfo "Restarting container..."
        stopSqlServer
        startSqlServer
        exit 0
        ;;
    "bash")
        logInfo "Attempting bash access..."
        bashAccess
        exit 0
        ;;
    "root")
        logInfo "Attempting root access..."
        rootAccess
        exit 0
        ;;
    "sql")
        logInfo "Attempting sqlcmd access..."
        sqlCmdUser
        exit 0
        ;;
    "test")
        logInfo "Attempting SQL Server test query..."
        testQuery
        exit 0
        ;;
    "status")
        showStatus
        exit 0
        ;;
    "logs")
        showLogs
        exit 0
        ;;
    "pull")
        pullImage
        exit 0
        ;;
    "remove")
        removeContainer
        exit 0
        ;;
    "help")
        showHelp
        exit 0
        ;;
    "")
        logInfo "No args provided. Starting menu interface..."
        ;;
    *)
        logError "Invalid argument: $1"
        logInfo "Run '$0 help' for usage information."
        exit 1
        ;;
esac

while true; do
    displayMenu

    case $menuChoice in
        1)
            startSqlServer
            ;;
        2)
            stopSqlServer
            ;;
        3)
            bashAccess
            ;;
        4)
            rootAccess
            ;;
        5)
            removeContainer
            ;;
        6)
            pullImage
            ;;
        7)
            showStatus
            ;;
        8)
            showLogs
            ;;
        9)
            cleanVolumes
            ;;
        10)
            doNothing
            ;;
        11)
            sqlCmdUser
            ;;
        12)
            testQuery
            ;;
        13)
            copyIn
            ;;
        14)
            copyOut
            ;;
        *)
            badChoice
            ;;
    esac

    if [[ $menuChoice =~ ^([1-9]|1[0-4])$ ]]; then
        INVALID_COUNT=0
    fi

    if [[ $menuChoice != 10 && $menuChoice =~ ^([1-9]|1[0-4])$ ]]; then
        echo
        read -p "Press Enter to continue..." dummy
    fi
done
