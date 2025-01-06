#!/bin/bash

#===================================================================================
#
#         FILE: mssqlPodman.sh
#
#        USAGE: run it
#
#  DESCRIPTION: Manages MSSQL Database Podman container
#      OPTIONS:  
# REQUIREMENTS: 
#       AUTHOR: Matt D
#      CREATED: 11.18.2021 - Docker version
#      UPDATED: 01.06.2025 - Podman version
#      VERSION: 2.0
#
#
#
#
#
#
#===================================================================================


# --- Utility Functions ---

function startUp()
{
    clear
    echo "##########################################################"
    echo "# This will manage your MSSQL Database Podman container  #"
    echo "##########################################################"

    echo
    echo "################################################"
    echo "#                                              #"
    echo "#    What would you like to do ?               #"
    echo "#                                              #"
    echo "#          1 ==   Start MSSQL container        #"
    echo "#          2 ==   Stop MSSQL container         #"
    echo "#          3 ==   Bash access                  #"
    echo "#          4 ==   SQLCMD                       #"
    echo "#          5 ==   Do NOTHING                   #"
    echo "#          6 ==   Clean unused volumes         #"
    echo "#          7 ==   Copy file into container     #"
    echo "#          8 ==   Copy file out of container   #"
    echo "#          9 ==   Root access                  #"
    echo "################################################"
    echo
    read -p "Please enter your choice: " whatwhat
}

function badChoice()
{
    echo "Invalid choice, please try again..."
    sleep 3
    startUp
}

function doNothing()
{
    echo "You chose to do nothing... Goodbye!"
    exit 0
}

# --- Podman-Specific Functions ---

function checkPodman()
{
    if ! podman ps > /dev/null 2>&1; then
        echo "Podman is not running. Starting Podman machine..."
        podman machine start
    fi
}

function createNetwork()
{
    podman network exists docknet || podman network create docknet
}

function startMssql()
{
    createNetwork
    checkPodman

    export mssqlRunning=$(podman ps --format "{{.Names}}" | grep -i MSSQL_DB_Container)
    export mssqlPresent=$(podman ps -a --format "{{.Names}}" | grep -i MSSQL_DB_Container)

    if [ "$mssqlRunning" == "MSSQL_DB_Container" ]; then
        echo "MSSQL container is already running."
    elif [ "$mssqlPresent" == "MSSQL_DB_Container" ]; then
        echo "MSSQL container found. Restarting..."
        podman restart MSSQL_DB_Container
    else
        echo "Provisioning a new MSSQL container..."
        podman run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=P@55VV0rd!' -e 'MSSQL_PID=Express' \
            --name MSSQL_DB_Container --network="docknet" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2017-latest-ubuntu
        echo "MSSQL container started successfully."
    fi
}

function stopMssql()
{
    checkPodman
    export stopMssql=$(podman ps --format "{{.ID}}" --filter "name=MSSQL_DB_Container")
    if [ -n "$stopMssql" ]; then
        echo "Stopping MSSQL container..."
        podman stop MSSQL_DB_Container
        cleanVolumes
    else
        echo "No running MSSQL container found."
    fi
}

function cleanVolumes()
{
    echo "Cleaning up unused volumes..."
    podman volume prune -f
    echo "Volumes cleaned successfully."
}

function bashAccess()
{
    checkPodman
    export mssqlImage=$(podman ps --format "{{.ID}}" --filter "name=MSSQL_DB_Container")
    podman exec -it $mssqlImage /bin/bash
}

function rootAccess()
{
    checkPodman
    export mssqlImage=$(podman ps --format "{{.ID}}" --filter "name=MSSQL_DB_Container")
    podman exec -it --user root $mssqlImage /bin/bash
}

function copyIn()
{
    checkPodman
    export mssqlRunning=$(podman ps --format "{{.Names}}" --filter "name=MSSQL_DB_Container")
    read -p "Enter the absolute path to the file to copy: " thePath
    read -p "Enter the file name: " theFile
    podman cp "$thePath/$theFile" "$mssqlRunning:/tmp/"
    echo "File copied to the container."
}

function copyOut()
{
    checkPodman
    export mssqlRunning=$(podman ps --format "{{.Names}}" --filter "name=MSSQL_DB_Container")
    read -p "Enter the container path to the file to copy: " thePath
    read -p "Enter the file name: " theFile
    podman cp "$mssqlRunning:$thePath/$theFile" /tmp/
    echo "File copied from the container."
}

function sqlCmd()
{
    checkPodman
    export mssqlImage=$(podman ps --format "{{.ID}}" --filter "name=MSSQL_DB_Container")
    podman exec -it $mssqlImage /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P@55VV0rd!
}

# --- Main Script ---

startUp
case $whatwhat in
    1) startMssql ;;
    2) stopMssql ;;
    3) bashAccess ;;
    4) sqlCmd ;;
    5) doNothing ;;
    6) cleanVolumes ;;
    7) copyIn ;;
    8) copyOut ;;
    9) rootAccess ;;
    *) badChoice ;;
esac
