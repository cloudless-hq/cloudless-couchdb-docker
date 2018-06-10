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

FROM buildpack-deps:jessie as ntr-base
ENV MAVEN_VERSION 3.5.2
ENV MAVEN_HOME /usr/share/maven
# install maven
RUN curl -fsSL http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share \
  && mv "/usr/share/apache-maven-${MAVEN_VERSION}" /usr/share/maven

# lean node setup to be re-used later
# FROM ntr-base as ntr-node
# RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
#  && apt-get -qq install -y nodejs

FROM erlang:18-slim as ntr-couchdb
RUN apt-get -qq update -y \
  && apt-get -qq install -y apt-utils \
  && apt-get -qq install -y --no-install-recommends \
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
  procps

RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get -qq install -y nodejs \
  && npm set progress=false && npm install -g grunt-cli

# get couchdb source
RUN mkdir /usr/src/couchdb && cd /usr/src/couchdb \
  && git clone https://github.com/neutrinity/couchdb . \
  && git checkout 350f5919685c82e821bb69110fd21fa4d7e101b9

# compile and install couchdb
RUN cd /usr/src/couchdb \
  && ./configure -c --disable-docs \
  && make release

# critical package deps preventing update: openjdk-7-jdk, libnspr4-0d, libicu52
FROM erlang:18-slim as ntr-couch-clouseau
ENV MAVEN_HOME /usr/share/maven
ENV COUCHDB_PATH /opt/couchdb
ENV CLOUSEAU_PATH /opt/clouseau

# setup maven
COPY --from=ntr-base /usr/share/maven /usr/share/maven
RUN ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && ls -l /usr/bin/mvn

# finish couchdb
RUN groupadd -r couchdb && useradd -d $COUCHDB_PATH -g couchdb couchdb
RUN apt-get -qq update -y \
  && apt-get -qq install -y apt-utils \
  && apt-get -qq install -y --no-install-recommends \
  python \
  build-essential \
  apt-transport-https \
  libnspr4 libnspr4-0d \
  openssl \
  curl \
  ca-certificates \
  git \
  pkg-config \
  openjdk-7-jdk \
  procps

COPY --from=ntr-couchdb /usr/src/couchdb/rel/couchdb "$COUCHDB_PATH"
RUN ls -l "$COUCHDB_PATH" && chown -R couchdb:couchdb "$COUCHDB_PATH"

# Install project dependencies and keep sources
# make source folder
RUN mkdir /clouseau_deps $CLOUSEAU_PATH

# install maven dependency packages (keep in image)
RUN cd clouseau_deps \
&& wget https://raw.githubusercontent.com/neutrinity/clouseau/ntr_master/pom.xml \
&& curl https://raw.githubusercontent.com/neutrinity/clouseau/ntr_master/src/main/assembly/distribution.xml --create-dirs -o src/main/assembly/distribution.xml \
&& mvn -T 1C install -Dmaven.test.skip=true

# now we can add all source code and start compiling
RUN cd /clouseau \
  && git clone -b ntr_master https://github.com/neutrinity/clouseau . \
  && cp -RT /clouseau_deps/ "${CLOUSEAU_PATH}/" && rm -r /clouseau_deps

RUN chown -R couchdb:couchdb $CLOUSEAU_PATH $COUCHDB_PATH

# TODO tests need to get unskipped
RUN  cd $CLOUSEAU_PATH && mvn verify -Dmaven.test.skip=true

# FIXME: this is for clouseau's start-script
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash - \
  && apt-get -qq install -y nodejs

COPY ./config/local.ini "$COUCHDB_PATH/etc/local.d/"
COPY ./config/vm.args "$COUCHDB_PATH/etc/"
RUN chown -R couchdb:couchdb "$COUCHDB_PATH/etc/local.d/" "$COUCHDB_PATH/etc/vm.args"

RUN mkdir "$COUCHDB_PATH/data"
VOLUME ["$COUCHDB_PATH/data"]

EXPOSE 5984

WORKDIR $COUCHDB_PATH

COPY ./start-couchdb $COUCHDB_PATH
COPY ./start-clouseau $COUCHDB_PATH

# Setup directories and permissions
RUN chmod +x start-couchdb && chmod +x start-clouseau && chown -R couchdb:couchdb $COUCHDB_PATH

RUN mkdir -p "$CLOUSEAU_PATH/target/clouseau1"
VOLUME ["$CLOUSEAU_PATH/target/clouseau1"]

USER couchdb
ENTRYPOINT ["${COUCHDB_PATH}/start-couchdb"]
