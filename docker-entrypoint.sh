#!/bin/bash
set -e

if [ "$1" = 'clouseau' ]; then
    # setup configuration
    echo '[clouseau]' > clouseau.ini
    echo "name=${NODE_NAME}" >> clouseau.ini
    echo "cookie=${ERLANG_COOKIE}" >> clouseau.ini
    echo "dir=${INDEX_DIR}" >> clouseau.ini

    # explicitely start local epmd since for scalang/clouseau there's no automatic launch mechanism like there is for erlang
    epmd -daemon

    mvn scala:run
fi

if [ "$1" = 'couchdb' ]; then
  chown -R couchdb:couchdb $COUCHDB_PATH

  chmod -R 0770 $COUCHDB_PATH/data

  chmod 664 $COUCHDB_PATH/etc/*.ini
  chmod 664 $COUCHDB_PATH/etc/local.d/*.ini
  chmod 775 $COUCHDB_PATH/etc/*.d

  echo "Setting up vm.args"
  cat $COUCHDB_PATH/etc/vm.args-dist > $COUCHDB_PATH/etc/vm.args
  echo "-setcookie '${ERLANG_COOKIE}'" >> $COUCHDB_PATH/etc/vm.args
  echo "-name ${NODE_NAME}" >> $COUCHDB_PATH/etc/vm.args

  if [ "$COUCHDB_USER" ] && [ "$COUCHDB_PASSWORD" ]; then
    # Create admin
    printf "[admins]\n%s = %s\n" "$COUCHDB_USER" "$COUCHDB_PASSWORD" > $COUCHDB_PATH/etc/local.d/docker.ini
    chown couchdb:couchdb $COUCHDB_PATH/etc/local.d/docker.ini
  fi

  if [ "$COUCHDB_SECRET" ]; then
    # Set secret
    printf "[couch_httpd_auth]\nsecret = %s\n" "$COUCHDB_SECRET" >> $COUCHDB_PATH/etc/local.d/docker.ini
    chown couchdb:couchdb $COUCHDB_PATH/etc/local.d/docker.ini
  fi

  # if we don't find an [admins] section followed by a non-comment, display a warning
  if ! grep -Pzoqr '\[admins\]\n[^;]\w+' $COUCHDB_PATH/etc/local.d/*.ini; then
    # The - option suppresses leading tabs but *not* spaces. :)
    cat >&2 <<-"EOWARN"
****************************************************
WARNING: CouchDB is running in Admin Party mode.
         This will allow anyone with access to the
         CouchDB port to access your database. In
         Docker's default configuration, this is
         effectively any other container on the same
         system.
         Use "-e COUCHDB_USER=admin -e COUCHDB_PASSWORD=password"
         to set it in "docker run".
****************************************************
EOWARN
  fi

  bin/couchdb
fi

# execute anything :-)
exec "$@"
