#!/bin/sh
#
# Script to backup database
#

echo "Backup started"
/home/sp/mongodb/bin/mongodump -d shapado-development -o backup
echo "Backup completed"
