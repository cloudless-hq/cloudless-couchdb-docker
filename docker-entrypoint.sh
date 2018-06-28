#!/bin/bash
set -e

if [ "$1" = 'clouseau' ]; then
    config="${CLOUSEAU_PATH}/etc/clouseau.ini"

    if [ -z "$NODE_NAME" ]; then
        node=$(hostname -f)
    else
        node=$NODE_NAME
    fi

    # setup configuration
    echo '[clouseau]' > $config
    echo "name=clouseau@${node}" >> $config
    echo "cookie=${ERLANG_COOKIE}" >> $config
    echo "dir=${INDEX_DIR}" >> $config

    # explicitely start local epmd since for scalang/clouseau there's no automatic launch mechanism like there is for erlang
    epmd -daemon

    java -Dlog4j.configuration=file:$CLOUSEAU_PATH/etc/log4j.properties \
    -cp $CLOUSEAU_PATH/etc:$CLOUSEAU_PATH/lib/* \
    com.cloudant.clouseau.Main \
    $config
fi

# execute anything :-)
exec "$@"
