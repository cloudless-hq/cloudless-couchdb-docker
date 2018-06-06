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
FROM apache/couchdb:2.1.1

ENV MAVEN_VERSION 3.5.2
ENV DEBIAN_FRONTEND noninteractive
ENV MAVEN_HOME /usr/share/maven

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
  python-sphinx \
  openjdk-7-jdk \
  procps

# install maven
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# get, compile and install clouseau
RUN mkdir /clouseau && chown -R couchdb:couchdb /clouseau /opt/couchdb

USER couchdb
RUN cd /clouseau \
  && git clone https://github.com/neutrinity/clouseau . \
  && mvn -D maven.test.skip=true install

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

COPY ./config/local.ini /opt/couchdb/etc/default.d/10-docker-default.ini
COPY ./config/vm.args /opt/couchdb/etc/
RUN chown -R couchdb:couchdb /opt/couchdb/etc/local.d/ /opt/couchdb/etc/vm.args

COPY ./start-couchdb /opt/couchdb/
RUN chmod +x /opt/couchdb/start-couchdb
COPY ./start-clouseau /opt/couchdb/
RUN chmod +x /opt/couchdb/start-clouseau

# Setup directories and permissions
RUN chown -R couchdb:couchdb /opt/couchdb

RUN mkdir /clouseau/target/clouseau1
VOLUME ["/clouseau/target/clouseau1"]

ENTRYPOINT ["/opt/couchdb/start-couchdb"]
