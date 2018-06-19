# --- Stage1: Get Maven ---
FROM buildpack-deps:jessie as ntr-base
ENV MAVEN_VERSION 3.5.2
ENV MAVEN_HOME /usr/share/maven
# install maven
RUN curl -fsSL "http://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz" | tar xzf - -C /usr/share \
  && mv "/usr/share/apache-maven-${MAVEN_VERSION}" /usr/share/maven
# -> used artifacts: /usr/share/maven

# --- Stage2: Install Clouseau
FROM erlang:18-slim as ntr-clouseau
ENV MAVEN_HOME /usr/share/maven
ENV CLOUSEAU_PATH /opt/clouseau
ENV INDEX_DIR /index

# setup maven
COPY --from=ntr-base /usr/share/maven $MAVEN_HOME
RUN ln -s /usr/share/maven/bin/mvn /usr/bin/mvn && ls -l /usr/bin/mvn

# finish clouseau
RUN groupadd -r clouseau && useradd -d "$CLOUSEAU_PATH" -g clouseau clouseau
RUN apt-get -qq update -y \
  && DEBIAN_FRONTEND=noninteractive apt-get -qq install -y apt-utils \
  && DEBIAN_FRONTEND=noninteractive apt-get -qq install -y --no-install-recommends \
  build-essential \
  apt-transport-https \
  libnspr4 libnspr4-0d \
  openssl \
  curl \
  ca-certificates \
  git \
  pkg-config \
  openjdk-7-jdk \
  && rm -rf /var/lib/apt/lists/*

# Install project dependencies and keep sources
# make source folder
RUN mkdir /clouseau_deps "$CLOUSEAU_PATH"

WORKDIR /clouseau_deps

# install maven dependency packages (keep in image)
RUN curl https://raw.githubusercontent.com/neutrinity/clouseau/ntr_master/pom.xml -o pom.xml \
&& curl https://raw.githubusercontent.com/neutrinity/clouseau/ntr_master/src/main/assembly/distribution.xml --create-dirs -o src/main/assembly/distribution.xml \
&& mvn -T 1C install -Dmaven.test.skip=true

WORKDIR $CLOUSEAU_PATH
# now we can add all source code and start compiling
RUN git clone -b ntr_master https://github.com/neutrinity/clouseau . \
  && cp -RT /clouseau_deps/ "${CLOUSEAU_PATH}/" && rm -r /clouseau_deps

# TODO tests need to get unskipped
RUN mvn verify -Dmaven.test.skip=true

COPY ./docker-entrypoint.sh $CLOUSEAU_PATH

# Setup directories and permissions
RUN touch clouseau.ini \
  && chmod +x docker-entrypoint.sh \
  && chown -R clouseau:clouseau "$CLOUSEAU_PATH"

RUN mkdir -p "$INDEX_DIR"
VOLUME ["$INDEX_DIR"]

USER clouseau
ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["clouseau"]
