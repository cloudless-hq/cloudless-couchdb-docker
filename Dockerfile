
FROM ubuntu:trusty

ENV COUCHDB_VERSION couchdb-search

ENV MAVEN_VERSION 3.3.3

ENV DEBIAN_FRONTEND noninteractive

RUN groupadd -r couchdb && useradd -d /usr/src/couchdb -g couchdb couchdb

# download dependencies
RUN apt-get update -y \
  && apt-get install -y --no-install-recommends build-essential libmozjs185-dev \
    libnspr4 libnspr4-0d libnspr4-dev libcurl4-openssl-dev libicu-dev \
    openssl curl ca-certificates git pkg-config \
    apt-transport-https python wget \
    python-sphinx texlive-base texinfo texlive-latex-extra texlive-fonts-recommended texlive-fonts-extra #needed to build the doc

RUN wget http://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_18.1-1~ubuntu~precise_amd64.deb
RUN apt-get install -y --no-install-recommends openjdk-7-jdk
RUN apt-get install -y --no-install-recommends procps
RUN apt-get install -y --no-install-recommends libwxgtk2.8-0

RUN dpkg -i esl-erlang_18.1-1~ubuntu~precise_amd64.deb

RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

ENV MAVEN_HOME /usr/share/maven

RUN curl -sL https://deb.nodesource.com/setup_6.x | bash - \
  && apt-get update -y && apt-get install -y nodejs \
  && npm install -g npm && npm install -g grunt-cli

RUN cd /usr/src \
 && git clone https://github.com/homerjam/couchdb \
 && cd couchdb \
 && git checkout cloudant-search \
 && ./configure --disable-docs \
 && make \
 && cp /usr/src/couchdb/dev/run /usr/local/bin/couchdb \
 && chmod +x /usr/src/couchdb/dev/run \
 && chown -R couchdb:couchdb /usr/src/couchdb

RUN cd /usr/src \
 && git clone https://github.com/cloudant-labs/clouseau \
 && cd /usr/src/clouseau \
 && mvn -Dmaven.test.skip=true install

RUN apt-get -y install haproxy

RUN apt-get install -y supervisor

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p /var/log/supervisor/ \
 && chmod 755 /var/log/supervisor/

# Expose to the outside
RUN sed -i 's/bind_address = 127.0.0.1/bind_address = 0.0.0.0/' /usr/src/couchdb/rel/overlay/etc/default.ini

EXPOSE 5984
WORKDIR /usr/src/couchdb

ENTRYPOINT ["/usr/bin/supervisord"]
