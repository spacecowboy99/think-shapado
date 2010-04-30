#!/bin/sh
#
# Script to start local environment
# Assumes you are root user

# Where does Shapado live?
SHAPADO_BASE="/home/sp/shapado-beta/"

# Where does MongoDB Binary?
MONGO_BASE="/home/sp/mongodb/bin/mongod"

# Where is Screen Binary?
SCREEN="/usr/bin/screen"

# Start new instances and bind them to screen so we can get to a console session
# "-S" names the session for easy re-attachment ; "-d -m" start new session but don't attach to it

echo "Start Mongo"
$SCREEN -S MONGO -d -m $MONGO_BASE

echo "Start Shapado"
cd $SHAPADO_BASE
$SCREEN -S SHAPADO -d -m script/server


$SCREEN -ls

# "screen -ls" lists attached screens
# "screen -d -r MONGO" re-attach to screen session at [NAME] or [PID]
# "^a^q" send a control-q, "^a^n" next window, "^a^d" detach, "^a^k" - kills
