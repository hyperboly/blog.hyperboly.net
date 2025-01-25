#!/usr/bin/env bash

USER=hyperboly
HOST=10.100.30.102 # Change this
DIR=/var/www/html/   # the directory where your website files should go

hugo && rsync -avz --delete public/ ${USER}@${HOST}:${DIR} # this will delete everything on the server that's not in the local public directory 

exit 0
