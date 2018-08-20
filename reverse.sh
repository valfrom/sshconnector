#!/bin/bash

REMOTE_HOSTNAME="YOUR_REMOTE_HOST"
REMOTE_PORT=YOUR_REMOTE_PORT
LOCAL_HOSTNAME=localhost
LOCAL_PORT=22


SSH_CONNECT_STRING="-N -C -o ServerAliveInterval=3 -g -R *:$REMOTE_PORT:$LOCAL_HOSTNAME:$LOCAL_PORT -p 22 root@$REMOTE_HOSTNAME"

function IsConnected {
    ssh user@$REMOTE_HOSTNAME -p $REMOTE_PORT -o ConnectTimeout=10 uname -a
    if [ ! $? -eq 0 ]; then
        return 1
    fi
    return 0
}

function Connect {
    ssh root@$REMOTE_HOSTNAME -o ConnectTimeout=15 /bin/bash << EOF
        lsof -t -i:$REMOTE_PORT | xargs kill
EOF
    ssh $SSH_CONNECT_STRING &
    connectionPid=$!
}

function WatchDogThread {
    while :
    do
        if ! IsConnected ; then
            echo "Not connected, try to connect.."
            if [ -n "$connectionPid" ]; then
                echo "Kill with pid: $connectionPid"
                kill $connectionPid
            fi
            Connect
        fi
        sleep 120
    done
}


function quit {
    echo "KILL THEM ALL!"
    kill $watchDogPid $connectionPid
}

trap quit EXIT

WatchDogThread&
watchDogPid=$!

wait
