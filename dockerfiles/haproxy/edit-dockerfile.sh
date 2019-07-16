#!/bin/bash

set -u

INSERTED_CONTENT_FILE=$1
FILE_TO_INSERT=$2

lead='^#START MARKER1$'
tail='^#END MARKER1$'

sed -e "/$lead/,/$tail/{ /$lead/{p; r $INSERTED_CONTENT_FILE
        }; /$tail/p; d }"  $FILE_TO_INSERT

