#/bin/bash
#

# set the platform to linux/amd64 so that mysql can be installed if running the build on a mac.
docker build --platform linux/amd64 -t "dalmatian-sql-backup:latest" .
