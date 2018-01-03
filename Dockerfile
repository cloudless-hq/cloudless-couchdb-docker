# Licensed under the Apache License, Version 2.0 (the "License"); you may not
# use this file except in compliance with the License. You may obtain a copy of
# the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations under
# the License.

FROM ubuntu:14.04

MAINTAINER NTR info@ntr.io

ENV COUCHDB_VERSION 2.1.1
ENV MAVEN_VERSION 3.5.2
ENV DEBIAN_FRONTEND noninteractive
ENV MAVEN_HOME /usr/share/maven

RUN groupadd -r couchdb && useradd -d /couchdb -g couchdb couchdb

RUN apt-get update -y \
  && apt-get install -y apt-utils \
  && apt-get install -y --no-install-recommends \
  build-essential \
  apt-transport-https \
  gcc \
  g++ \
  libcurl4-openssl-dev \
  libicu-dev \
  libmozjs185-dev \
  make \
  libmozjs185-1.0 \
  libnspr4 libnspr4-0d libnspr4-dev \
  openssl \
  curl \
  ca-certificates \
  git \
  pkg-config \
  python \
  haproxy \
  wget \
  libicu52 \
  python-sphinx \
  texlive-base \
  texinfo \
  texlive-latex-extra \
  texlive-fonts-recommended \
  texlive-fonts-extra \
  openjdk-7-jdk \
  procps \
  libwxgtk2.8-0 \
  && rm -rf /var/lib/apt/lists/*

RUN wget http://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_18.1-1~ubuntu~precise_amd64.deb
RUN dpkg -i esl-erlang_18.1-1~ubuntu~precise_amd64.deb

# install maven
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g pm2 \
  && npm install -g grunt-cli

# get couchdb source
RUN cd /usr/src \
  && git clone https://github.com/neutrinity/couchdb \
  && cd couchdb \
  && git checkout 56245328ee96c828f27dea9365dc4347921791e6

# compile and install couchdb
RUN cd /usr/src/couchdb \
  && ./configure -c --disable-docs \
  && make release \
  && cp /usr/src/couchdb/dev/run /usr/local/bin/couchdb \
  && mv /usr/src/couchdb/rel/couchdb /couchdb

# Setup directories and permissions
RUN chown -R couchdb:couchdb /couchdb \
  && chmod +x /usr/local/bin/couchdb

# get, compile and install clouseau
RUN cd /usr/src \
  && git clone https://github.com/neutrinity/clouseau \
  && cd /usr/src/clouseau \
  && mvn -D maven.test.skip=true install \
  && mkdir /clouseau \
  && mv /usr/src/clouseau /clouseau

# Cleanup build detritus
RUN apt-get purge -y --auto-remove apt-transport-https \
  gcc \
  g++ \
  libcurl4-openssl-dev \
  libicu-dev \
  libmozjs185-dev \
  make \
  && rm -rf /var/lib/apt/lists/* /usr/src/couchdb* /usr/src/clouseau*

COPY ./config/local.ini /couchdb/etc/local.d/
COPY ./config/vm.args /couchdb/etc/
RUN chown -R couchdb:couchdb /couchdb/etc/local.d/ /couchdb/etc/vm.args

VOLUME ["/couchdb/data"]
VOLUME ["/couchdb/config"]

EXPOSE 5984 4369 9100 5986 15984

WORKDIR /couchdb

COPY ./config/pm2.json /couchdb/

COPY ./docker-entrypoint.sh /couchdb/
RUN chmod +x /couchdb/docker-entrypoint.sh \
  && chown -R couchdb:couchdb /couchdb/docker-entrypoint.sh

CMD ["pm2-docker", "--raw", "start", "--json", "--auto-exit", "pm2.json"]
