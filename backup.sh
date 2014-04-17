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

if [ DEBUG ]; then
    echo "DEBUG mode, nothing will be commited to git repository"
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

if [ -d .git ]; then
    :
else
    echo "Create git repository (git init) with origin remote (git remote add origin <url>)." >&2
    exit 3
fi

if [ -f .gitignore ]; then
        :
else
    echo "/tmp/" | cat > .gitignore
	git add .gitignore
    git commit -m "Create .gitignore file"
fi

GIT_ORIGIN=$(git remote -v | grep origin | wc -l | tr -d ' ')
if [ $GIT_ORIGIN -eq 0 ]; then
    echo "Add origin remote to repository (git remote add origin <url>)." >&2
    exit 4
fi

# Clear tmp directory if previous backup failed
if [ -d tmp ]; then
    rm -rf tmp
fi

echo "pg_dump of $DATABASE database for $USERNAME username"
pg_dump --format directory --compress 0 --file tmp --username $USERNAME $DATABASE
if [ -d tmp -a $(ls -l tmp | grep total | cut -d ' ' -f 2) -gt 0 ]; then
    echo "Sort *.dat files"
    for f in ./tmp/* ; do
        if [ $(basename $f) = "toc.dat" ]; then
            # Move binary toc.dat file without changes
            mv $f .
        else
            $DEBUG && echo "Sort $(basename $f)"
            # Sort rows by id and strip them from empty lines and \.
            sort -gk 1 $f | egrep -v "^(\\\.)?$" > $(basename $f)
            # Append missing "\." line to sorted file
            echo "\." >> $(basename $f)
            # Remove tmp file after sorting
            rm $f
        fi
    done

    # Remove tmp dir - it should be empty when sorting is done
    rmdir tmp
    # Update db.list file
    pg_restore --list . > db.list
else
    echo "pg_dump failed. Abording" >&2
    exit 5
fi

if [ $DEBUG = true ]; then
    echo "Skip git commands"
else
    echo "Add files to git"
    git add .
    FILES_CHANGED=$(git status | grep "modified\|new file" | grep -v "toc.dat" | grep -v "db.list" | wc -l | tr -d ' ')
    if [ $FILES_CHANGED -gt 0 ]; then
        echo "New data detected, create and push commit"
        git commit -am "Automatic backup"
        git pull origin master
        git push origin master
    fi

fi