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

# critical package deps preventing update: openjdk-7-jdk, libnspr4-0d, libwxgtk2.8-0, libicu52
FROM ubuntu:14.04

ENV MAVEN_VERSION 3.5.2
ENV DEBIAN_FRONTEND noninteractive
ENV MAVEN_HOME /usr/share/maven

RUN groupadd -r couchdb && useradd -d /couchdb -g couchdb couchdb

RUN apt-get update -y \
  && apt-get install -y apt-utils \
  && apt-get install -y --no-install-recommends \
  python \
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
  wget \
  libicu52 \
  libwxgtk2.8-0 \
  openjdk-7-jdk \
  procps

RUN wget -nv http://packages.erlang-solutions.com/erlang/esl-erlang/FLAVOUR_1_general/esl-erlang_18.1-1~ubuntu~precise_amd64.deb
RUN dpkg -i esl-erlang_18.1-1~ubuntu~precise_amd64.deb

# install maven
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# install nodejs
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get install -y nodejs \
  && npm install -g grunt-cli

# get couchdb source
RUN mkdir /usr/src/couchdb && cd /usr/src/couchdb \
  && git clone https://github.com/neutrinity/couchdb . \
  && git checkout 2d100fc8e0df613c71406d3a2d7d5932658c5c8a

# compile and install couchdb
RUN cd /usr/src/couchdb \
  && ./configure -c --disable-docs \
  && make release \
  && mv /usr/src/couchdb/rel/couchdb /couchdb

# Install project dependencies and keep sources
# make source folder
RUN mkdir /clouseau_deps /clouseau

# install maven dependency packages (keep in image)
RUN cd clouseau_deps \
&& wget https://raw.githubusercontent.com/neutrinity/clouseau/ntr_master/pom.xml \
&& curl https://raw.githubusercontent.com/neutrinity/clouseau/ntr_master/src/main/assembly/distribution.xml --create-dirs -o src/main/assembly/distribution.xml \
&& mvn -T 1C install -Dmaven.test.skip=true

# now we can add all source code and start compiling
RUN cd /clouseau \
  && git clone -b ntr_master https://github.com/neutrinity/clouseau . \
  && cp -RT /clouseau_deps/ /clouseau/ && rm -r /clouseau_deps

RUN chown -R couchdb:couchdb /clouseau /couchdb
USER couchdb

# TODO tests need to get unskipped
RUN  cd /clouseau && mvn verify -Dmaven.test.skip=true

USER root

# Cleanup build detritus
RUN apt-get purge -y --auto-remove apt-transport-https \
  gcc \
  g++ \
  libcurl4-openssl-dev \
  libicu-dev \
  libmozjs185-dev \
  make \
  && rm -rf /var/lib/apt/lists/* /usr/src/couchdb*

COPY ./config/local.ini /couchdb/etc/local.d/
COPY ./config/vm.args /couchdb/etc/
RUN chown -R couchdb:couchdb /couchdb/etc/local.d/ /couchdb/etc/vm.args

RUN mkdir /couchdb/data
VOLUME ["/couchdb/data"]

EXPOSE 5984

WORKDIR /couchdb

COPY ./start-couchdb /couchdb/
RUN chmod +x /couchdb/start-couchdb
COPY ./start-clouseau /couchdb/
RUN chmod +x /couchdb/start-clouseau

# Setup directories and permissions
RUN chown -R couchdb:couchdb /couchdb

USER couchdb

RUN mkdir -p /clouseau/target/clouseau1
VOLUME ["/clouseau/target/clouseau1"]

ENTRYPOINT ["/couchdb/start-couchdb"]
