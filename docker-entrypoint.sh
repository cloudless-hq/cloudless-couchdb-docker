#!/bin/bash
set -e

if [ "$1" = 'clouseau' ]; then
    # setup configuration
    echo '[clouseau]' > "${CLOUSEAU_PATH}/etc/clouseau.ini"
    echo "name=clouseau@${NODE_NAME}" >> "${CLOUSEAU_PATH}/etc/clouseau.ini"
    echo "cookie=${ERLANG_COOKIE}" >> "${CLOUSEAU_PATH}/etc/clouseau.ini"
    echo "dir=${INDEX_DIR}" >> "${CLOUSEAU_PATH}/etc/clouseau.ini"

    # explicitely start local epmd since for scalang/clouseau there's no automatic launch mechanism like there is for erlang
    epmd -daemon

    java -Dlog4j.configuration=file:$CLOUSEAU_PATH/etc/log4j.properties \
    -cp $CLOUSEAU_PATH/etc:$CLOUSEAU_PATH/lib/* \
    com.cloudant.clouseau.Main \
    "${CLOUSEAU_PATH}/etc/clouseau.ini"
fi

# execute anything :-)
exec "$@"
