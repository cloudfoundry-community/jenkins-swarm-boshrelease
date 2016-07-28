#!/bin/bash

function usage() {

cat << EOF

    USAGE: $0 [help | clean-blobs | clean-build | clean-all ]
    
        clean-blobs: force re-download of all blobs
        clean-build: reset dev build number
        clean-all: do both clean-blobs and clean-build

EOF
    
    exit 0
}

function clean_blobs() {
    rm -fr blobs
    rm -fr .downloads
}

function clean_build() {
    rm -fr dev_releases
    rm -fr config/dev.yml
    bosh -n delete deployment jenkins 2>&1 > /dev/null
    bosh -n delete release jenkins-swarm 2>&1 > /dev/null
}

ROOTDIR=$(cd $(dirname $0) && pwd)

BUILD_ACTION=${1:-build}
case "$BUILD_ACTION" in
    clean-blobs)
        clean_blobs
        ;;
    clean-build)
        clean_build
        ;;
    clean-all)
        clean_blobs
        clean_build
        ;;
    build)
        ;;
    help)
        usage
        ;;
    *)
        usage
        ;;
esac

which bosh 2>&1 > /dev/null
if [ $? != 0 ]; then
    echo -e "ERROR! You need the bosh cli to add the package blobs to your release."
fi

set -x

# Package versions

JRE_VERSION=8u91
JRE_BUILD=14

JENKINS_VERSION=1.651.2
SWARM_CLIENT_VERSION=2.1

# Download packages and upload them to local blob directory

mkdir -p $ROOTDIR/.downloads

set -e

cd $ROOTDIR/.downloads
JRE_TAR=jre-${JRE_VERSION}-linux-x64.tar.gz
if [ ! -e ${JRE_TAR} ]; then
    JRE_URL=http://download.oracle.com/otn-pub/java/jdk/${JRE_VERSION}-b${JRE_BUILD}/jre-${JRE_VERSION}-linux-x64.tar.gz
    wget -c -O ${JRE_TAR} --no-check-certificate --no-cookies --header "Cookie: oraclelicense=accept-securebackup-cookie" "${JRE_URL}"
    rm -f jre.tar.gz
    ln -s ${JRE_TAR} jre.tar.gz
    cd $ROOTDIR
    bosh add blob $ROOTDIR/.downloads/jre.tar.gz java
else
    cd $ROOTDIR
fi

cd $ROOTDIR/.downloads
JENKINS_WAR=jenkins-${JENKINS_VERSION}.war
if [ ! -e ${JENKINS_WAR} ]; then
    JENKINS_DOWNLOAD_URL=http://mirrors.jenkins-ci.org/war-stable/${JENKINS_VERSION}/jenkins.war
    wget -c -O ${JENKINS_WAR} --no-check-certificate --no-cookies "${JENKINS_DOWNLOAD_URL}"
    rm -f jenkins.war
    ln -s ${JENKINS_WAR} jenkins.war
    cd $ROOTDIR
    bosh add blob $ROOTDIR/.downloads/jenkins.war jenkins
else
    cd $ROOTDIR
fi

cd $ROOTDIR/.downloads
SWARM_CLIENT_JAR=swarm-client-${SWARM_CLIENT_VERSION}.jar
if [ ! -e ${SWARM_CLIENT_JAR} ]; then
    SWARM_CLIENT_DOWNLOAD_URL=http://repo.jenkins-ci.org/releases/org/jenkins-ci/plugins/swarm-client/${SWARM_CLIENT_VERSION}/swarm-client-${SWARM_CLIENT_VERSION}-jar-with-dependencies.jar
    wget -c -O ${SWARM_CLIENT_JAR} --no-check-certificate --no-cookies "${SWARM_CLIENT_DOWNLOAD_URL}"
    rm -f swarm-client.war
    ln -s ${SWARM_CLIENT_JAR} swarm-client.jar
    cd $ROOTDIR
    bosh add blob $ROOTDIR/.downloads/swarm-client.jar jenkins
else
    cd $ROOTDIR
fi

cd $ROOTDIR/.downloads
PLUGINS_ARCHIVE=plugins.tar.gz
if [ ! -e ${PLUGINS_ARCHIVE} ]; then
    export JENKINS_HOME=$ROOTDIR/.downloads/jenkins
    ../jobs/jenkins/templates/bin/install_jenkins_plugins.sh git swarm workflow-aggregator docker-workflow
    tar cvzf $PLUGINS_ARCHIVE -C jenkins ./plugins
    cd $ROOTDIR
    bosh add blob $ROOTDIR/.downloads/$PLUGINS_ARCHIVE jenkins
else
    cd $ROOTDIR
fi

set +e
bosh releases | grep "docker" 2>&1 > /dev/null
if [ $? == 1 ]; then
    bosh upload release https://bosh.io/d/github.com/cf-platform-eng/docker-boshrelease
fi
set -e

# Build bosh release

bosh create release --with-tarball --force --name jenkins-swarm
bosh upload release

set +x
