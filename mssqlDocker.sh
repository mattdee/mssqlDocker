#!/bin/bash
#
#
   #===================================================================================
   #
   #         FILE: mssqlDocker.sh
   #
   #        USAGE: run it
   #
   #  DESCRIPTION:
   #      OPTIONS:  
   # REQUIREMENTS: 
   #       AUTHOR: Matt D
   #      CREATED: 11.18.2021
   #      UPDATED: 11.18.2021
   #      VERSION: 1.0
   #
   #
   #
   #
   #
   #
   #===================================================================================


function startUp()
{
    clear screen
    echo "##########################################################"
    echo "# This will manage your MSSQL Database Docker container  #"
    echo "##########################################################"

    echo
    echo
    echo 

    echo "################################################"
    echo "#                                              #"
    echo "#    What would you like to do ?               #"
    echo "#                                              #"
    echo "#          1 ==   Start MSSQL  docker image    #"
    echo "#                                              #"
    echo "#          2 ==   Stop MSSQL docker image      #"
    echo "#                                              #"
    echo "#          3 ==   Bash access                  #"            
    echo "#                                              #"
    echo "#          4 ==   SQLCMD                       #"
    echo "#                                              #"
    echo "#          5 ==   Do NOTHING                   #"
    echo "#                                              #"
    echo "################################################"
    echo 
    echo "Please enter in your choice:> "
    read whatwhat

#   if [ $whatwhat -gt 9 ]
#       then
#       echo "Please enter a valid choice"
#       sleep 3
#       startUp
#   fi
    
}

function helpMe()
{
    echo "Help wanted..."
    sleep 5
    startUp
}

function doNothing()
{
    echo "################################################"
    echo "You don't want to do nothing...lazy..."
    echo "So...you want to quit...yes? "
    echo "Enter yes or no"
    echo "################################################"
    read doWhat
    if [[ $doWhat = yes ]]; then
        echo "Yes"
        echo "Bye! ¯\_(ツ)_/¯ " 
        exit 1
    else
        echo "No"
        startUp
    fi
    
}

function countDown()
{
    row=2
    col=2
    
    clear 
    msg="Please wait for MSSQL to start ...${1}..."
    tput cup $row $col
    echo -n "$msg"
    l=${#msg}
    l=$(( l+$col ))
    for i in {30..1}
        do
            tput cup $row $l
            echo -n "$i"
            sleep 1
         done
    startUp
}

function badChoice()
{
    echo "Invalid choice, please try again..."
    sleep 5
    startUp
}

function checkDocker()
{
    # open Docker, only if is not running...super hacky
    if (! docker stats --no-stream ); then
        open /Applications/Docker.app
    while (! docker stats --no-stream ); do
        echo "Waiting for Docker to launch..."
        sleep 1
    done
    fi
}

function copyFile()
{
    checkDocker
    export mssqlRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $2}' )
    echo "Please enter the ABSOLUTE PATH to the file you want copied: "
    read thePath
    echo "Please enter the FILE NAME you want copied: "
    read theFile
    echo "Copying info: " $thePath/$theFile
    docker cp $thePath/$theFile $mssqlRunning:/tmp

}



function startMssql() # start or restart the container named MSSQL_DB_Container
{   
    checkDocker
    # check to see if MSSQL_DB_Container is running and if running exit
    export mssqlRunning=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $2}' )
    export mssqlPresent=$(docker container ls -a --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $2}')

    if [ "$mssqlRunning" == "MSSQL_DB_Container" ]; then
        echo "MSSQL docker container is running, please select other option."
        sleep 5
        startUp
    elif [ "$mssqlPresent" == "MSSQL_DB_Container" ]; then
        echo "MSSQL docker container found, restarting..."
        docker restart $mssqlPresent
        countDown
    else
        echo "No MSSQL docker image found, provisioning..."
        docker run -e 'ACCEPT_EULA=Y' -e 'SA_PASSWORD=P@55VV0rd!' -e 'MSSQL_PID=Express' --name MSSQL_DB_Container --network="bridge" -p 1433:1433 -d mcr.microsoft.com/mssql/server:2017-latest-ubuntu 
        export runningAs=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $2}' )
        echo "MSSQL is running as: "$runningAs
        echo "Please be patient as it takes time for the container to start..."
        countDown
    fi

}


function stopMssql()
{
    checkDocker
    export stopMssql=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $1}' )
    echo $stopMssql

    for i in $stopMssql
    do
        echo $i
        echo "Stopping container: " $i
        docker stop $i
    done

    cleanVolumes

}


function cleanVolumes()
{
    docker volume prune -f 
}


function bashAccess()
{
    checkDocker
    export mssqlImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $1}' )
    docker exec -it $mssqlImage /bin/bash
}

function rootAccess()
{
    checkDocker
    #export mssqlImage=$(docker ps --format "table {{.Image}}\t{{.Ports}}\t{{.Names}}"| grep -i oracle  | awk '{print $4}')
    # this works by greping the known oracle database port
    export mssqlImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $1}' )
    docker exec -it -u 0 $mssqlImage /bin/bash
}

function showDatabases()
{
    checkDocker
    export mssqlImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $1}' )
    docker exec $mssqlImage /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P@55VV0rd! -Q "SELECT name, database_id, create_date FROM sys.databases;"
}

function sqlCmd()
{
    checkDocker
    showDatabases
    export mssqlImage=$(docker ps --no-trunc --format "table {{.ID}}\t {{.Names}}\t" | grep -i MSSQL_DB_Container  | awk '{print $1}' )
    docker exec -it $mssqlImage /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P P@55VV0rd!
}

# process arguements to bypass the menu
if [ "$1" = "start" ]; then
    echo "Starting container..."
    startMssql 
    elif
    [ "$1" = "stop" ]; then
        echo "Stopping container..."
        stopMssql
    elif 
        [ "$1" = "bash" ]; then
            echo "Attempting bash acess..."
            bashAccess
    elif 
        [ "$1" = "sql" ]; then
        echo "Attempting sqlcmd access..."
        sqlCmd
    elif
        [ "$1" = "help" ]; then
            echo "Providing help..."
            helpMe
    elif [ -z "$1" ]; then
        echo "No args...proceed with menu"
        #sleep 3
fi



# Let's go to work
startUp
case $whatwhat in
    1) 
        startMssql
        ;;
    2) 
        stopMssql
        ;;
    3)
        bashAccess
        ;;   
    4)
        sqlCmd
        ;;
    5)
        doNothing
        ;;
    6)  # secret menu like in-n-out ;-) 
        cleanVolumes
        ;;
    7)
        copyFile
        ;;
    8)
        rootAccess
        ;;
    *) 
        badChoice
esac


