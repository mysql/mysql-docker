#!/bin/bash
set -x
set -e

source ./VERSION

REPO=https://repo.mysql.com; [ -n "$1" ] && REPO=$1
CONFIG_PACKAGE_NAME=mysql80-community-release-el8.rpm; [ -n "$2" ] && CONFIG_PACKAGE_NAME=$2
MYSQL_CLIENT_PACKAGE_NAME=mysql-community-client; [ -n "$3" ] && MYSQL_CLIENT_PACKAGE_NAME=$3
MYSQL_ROUTER_PACKAGE_NAME=mysql-router-community; [ -n "$4" ] && MYSQL_ROUTER_PACKAGE_NAME=$4
MYSQL_CLIENT_VERSION=mysql-community-client; [ -n "$5" ] && MYSQL_CLIENT_VERSION=$5
MYSQL_ROUTER_VERSION=mysql-router-community; [ -n "$6" ] && MYSQL_ROUTER_VERSION=$6
REPO_NAME_SERVER=mysql80-community; [ -n "$7" ] && REPO_NAME_SERVER=$7
REPO_NAME_TOOLS=mysql-tools-community; [ -n "$8" ] && REPO_NAME_TOOLS=$8

MAJOR_VERSION=$(echo $MYSQL_CLIENT_VERSION | cut -d'.' -f'1,2')

MYSQL_CLIENT_PACKAGE=$MYSQL_CLIENT_PACKAGE_NAME-$MYSQL_CLIENT_VERSION
MYSQL_ROUTER_PACKAGE=$MYSQL_ROUTER_PACKAGE_NAME-$MYSQL_ROUTER_VERSION

echo "In the place"
echo `ls`
if [ ! -d "${MAJOR_VERSION}" ]; then
  mkdir -p "${MAJOR_VERSION}/inspec"
fi
echo `ls -lrt`
echo 'inside 8.1'
echo `ls -lrt 8.1`

sed 's#%%MYSQL_CLIENT_PACKAGE%%#'"${MYSQL_CLIENT_PACKAGE}"'#g' template/Dockerfile > tmpFile
sed -i 's#%%MYSQL_ROUTER_PACKAGE%%#'"${MYSQL_ROUTER_PACKAGE}"'#g' tmpFile
sed -i 's#%%CONFIG_PACKAGE_NAME%%#'"${CONFIG_PACKAGE_NAME}"'#g' tmpFile
sed -i 's#%%REPO%%#'"${REPO}"'#g' tmpFile
sed -i 's#%%REPO_NAME_SERVER%%#'"${REPO_NAME_SERVER}"'#g' tmpFile
sed -i 's#%%REPO_NAME_TOOLS%%#'"${REPO_NAME_TOOLS}"'#g' tmpFile
mv tmpFile ${MAJOR_VERSION}/Dockerfile

# update test template
sed -e 's#%%MYSQL_CLIENT_PACKAGE_NAME%%#'"${MYSQL_CLIENT_PACKAGE_NAME}"'#g' template/control.rb > tmpFile
sed -i -e 's#%%MYSQL_CLIENT_VERSION%%#'"${MYSQL_CLIENT_VERSION}"'#g' tmpFile
sed -i -e 's#%%MYSQL_ROUTER_PACKAGE_NAME%%#'"${MYSQL_ROUTER_PACKAGE_NAME}"'#g' tmpFile
sed -i -e 's#%%MYSQL_ROUTER_VERSION%%#'"${MYSQL_ROUTER_VERSION}"'#g' tmpFile
sed -i -e 's#%%MAJOR_VERSION%%#'"${MAJOR_VERSION}"'#g' tmpFile
mv tmpFile "${MAJOR_VERSION}/inspec/control.rb"

# copy entrypoint script
cp template/run.sh ${MAJOR_VERSION}/run.sh
chmod +x ${MAJOR_VERSION}/run.sh

cp README.md ${MAJOR_VERSION}/
