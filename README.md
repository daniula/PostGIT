PostGIT
=======

Script making Postgres database dump in directory format and pushing changes to your GIT repository.

Usage
-----

`postgit backup|restore -u POSTGRES_USERNAME -d POSTGRES_DATABASE [-h POSTGRES_HOST -p POSTGRES_PORT ] -o OUTPUT_DIRECTORY [-q -x]`

* -o OUTPUT_DIRECTORY should have git repository with added git remote origin for branch master.
* -q Silence out output to stdout.
* -x Is for testing. Skips git push command at the end of script.

