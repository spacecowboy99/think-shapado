#!/bin/sh
#
# Script to backup database
#

echo "Restore started"
sudo ~/mongodb/bin/mongorestore -d shapado-development  backup/shapado-development --drop
sudo ~/mongodb/bin/mongorestore -d shapado-development  backup/shapado-development
echo "Restore completed"
