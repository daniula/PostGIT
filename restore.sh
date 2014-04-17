#!/bin/bash

DEBUG=false
while getopts ":xqd:u:" opt; do
    case $opt in
        x) DEBUG=true
        ;;
        q) exec 1>/dev/null
        ;;
        u) USERNAME=$OPTARG
        ;;
        d) DATABASE=$OPTARG
        ;;
    esac
done

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

if [[ $USERNAME = "" || $DATABASE = "" ]]; then
    echo "Parameters: -u username and -d database are required." >&2
    exit 1
fi

if [ -f ~/.pgpass ]; then
    :
else
    echo "Create ~/.pgpass file with access to Postgres in format: hostname:port:database:username:password" >&2
    exit 2
fi

PGPASS_CHMOD=$(ls -l ~/.pgpass | cut -d ' ' -f 1 | tr -d '\s\n' | tail -c 6)
if [ $PGPASS_CHMOD = "------" ]; then
    :
else
    echo "Change ~/.pgpass permissions to 0600 (chmod 0600 ~/.pgpass)."
    exit 2
fi

pg_restore --use-list db.list --clean --username $USERNAME --dbname $DATABASE --schema public .