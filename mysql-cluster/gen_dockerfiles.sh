#!/bin/bash
# Copyright (c) 2017, 2023, Oracle and/or its affiliates.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

set -e

# This script will simply use sed to replace placeholder variables in the
# files in template/ with version-specific variants.

source ./VERSION

REPO=https://repo.mysql.com; [ -n "$1" ] && REPO=$1
MYSQL_VERSION=""; [ -n "$2" ] && MYSQL_VERSION=$2
SHELL_VERSION=""; [ -n "$3" ] && SHELL_VERSION=$3
CONFIG_PACKAGE_NAME=mysql80-community-release-el8.rpm; [ -n "$4" ] && CONFIG_PACKAGE_NAME=$4
CONFIG_PACKAGE_NAME_MINIMAL=mysql-cluster-community-minimal-release-el8.rpm; [ -n "$5" ] && CONFIG_PACKAGE_NAME_MINIMAL=$5

REPO_NAME_SERVER=mysql-cluster80-community-minimal; [ -n "$6" ] && REPO_NAME_SERVER=$6
REPO_NAME_TOOLS=mysql-tools-community; [ -n "$7" ] && REPO_NAME_TOOLS=$7

MYSQL_SERVER_PACKAGE_NAME="mysql-cluster-community-server-minimal"; [ -n "$8" ] && MYSQL_SERVER_PACKAGE_NAME=$8
MYSQL_SHELL_PACKAGE_NAME="mysql-shell"; [ -n "$9" ] && MYSQL_SHELL_PACKAGE_NAME=$9

declare -A PORTS
PORTS["7.5"]="3306 33060 2202 1186"
PORTS["7.6"]="3306 33060 2202 1186"
PORTS["8.0"]="3306 33060-33061 2202 1186"
PORTS["$LATEST_INNOVATION"]="3306 33060-33061 2202 1186"

declare -A PASSWORDSET
PASSWORDSET["7.5"]="ALTER USER 'root'@'localhost' IDENTIFIED BY '\${MYSQL_ROOT_PASSWORD}';"
PASSWORDSET["7.6"]=${PASSWORDSET["7.5"]}
PASSWORDSET["8.0"]=${PASSWORDSET["7.6"]}
PASSWORDSET["$LATEST_INNOVATION"]=${PASSWORDSET["7.6"]}

declare -A DATABASE_INIT
DATABASE_INIT["7.5"]="\"\$@\" --user=\$MYSQLD_USER --initialize-insecure"
DATABASE_INIT["7.6"]="\"\$@\" --user=\$MYSQLD_USER --initialize-insecure"
DATABASE_INIT["8.0"]="\"\$@\" --user=\$MYSQLD_USER --initialize-insecure"
DATABASE_INIT["$LATEST_INNOVATION"]="\"\$@\" --user=\$MYSQLD_USER --initialize-insecure"

declare -A STARTUP
STARTUP["7.5"]="exec \"\$@\" --user=\$MYSQLD_USER"
STARTUP["7.6"]="exec \"\$@\" --user=\$MYSQLD_USER"
STARTUP["8.0"]="export MYSQLD_PARENT_PID=\$\$ ; exec \"\$@\" --user=$MYSQLD_USER"
STARTUP["$LATEST_INNOVATION"]="export MYSQLD_PARENT_PID=\$\$ ; exec \"\$@\" --user=$MYSQLD_USER"


declare -A STARTUP_WAIT
STARTUP_WAIT["7.5"]="\"\""
STARTUP_WAIT["7.6"]="\"\""


# MySQL 8.0 supports a call to validate the config, while older versions have it as a side
# effect of running --verbose --help
declare -A VALIDATE_CONFIG
VALIDATE_CONFIG["7.5"]="output=\$(\"\$@\" --verbose --help 2>\&1 > /dev/null) || result=\$?"
VALIDATE_CONFIG["7.6"]="output=\$(\"\$@\" --verbose --help 2>\&1 > /dev/null) || result=\$?"
VALIDATE_CONFIG["8.0"]="output=\$(\"\$@\" --validate-config) || result=\$?"
VALIDATE_CONFIG["$LATEST_INNOVATION"]="output=\$(\"\$@\" --validate-config) || result=\$?"

# Data directories that must be created with special ownership and permissions when the image is built
declare -A PRECREATE_DIRS
PRECREATE_DIRS["7.5"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"
PRECREATE_DIRS["7.6"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"
PRECREATE_DIRS["8.0"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"
PRECREATE_DIRS["$LATEST_INNOVATION"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"

process_version() {
  MAJOR_VERSION=$1
  MYSQL_SERVER_PACKAGE=${MYSQL_SERVER_PACKAGE_NAME}${SERVER_PKG_SUFFIX}
  MYSQL_SHELL_PACKAGE=${MYSQL_SHELL_PACKAGE_NAME}${SHELL_PKG_SUFFIX}

  # Dockerfiles
  DOCKERFILE_TEMPLATE=template/Dockerfile
  if [[ "${MAJOR_VERSION}" =~ 7\.(5|6) ]]; then
    DOCKERFILE_TEMPLATE=template/Dockerfile-pre8
  fi

  # Dockerfile_spec.rb
  if [ ! -d "${MAJOR_VERSION}" ]; then
    mkdir "${MAJOR_VERSION}"
  fi

  sed 's#%%MYSQL_SERVER_PACKAGE%%#'"${MYSQL_SERVER_PACKAGE}"'#g' $DOCKERFILE_TEMPLATE > tmpfile
  sed -i 's#%%REPO%%#'"${REPO}"'#g' tmpfile
  REPO_VERSION=${MAJOR_VERSION//\./}
  sed -i 's#%%REPO_VERSION%%#'"${REPO_VERSION}"'#g' tmpfile

  sed -i 's#%%CONFIG_PACKAGE_NAME%%#'"${CONFIG_PACKAGE_NAME}"'#g' tmpfile
  sed -i 's#%%CONFIG_PACKAGE_NAME_MINIMAL%%#'"${CONFIG_PACKAGE_NAME_MINIMAL}"'#g' tmpfile
  sed -i 's#%%REPO_NAME_SERVER%%#'"${REPO_NAME_SERVER}"'#g' tmpfile
  sed -i 's#%%REPO_NAME_TOOLS%%#'"${REPO_NAME_TOOLS}"'#g' tmpfile
  sed -i 's#%%MYSQL_SHELL_PACKAGE%%#'"${MYSQL_SHELL_PACKAGE}"'#g' tmpfile
  sed -i 's/%%PORTS%%/'"${PORTS[${MAJOR_VERSION}]}"'/g' tmpfile
  mv tmpfile ${MAJOR_VERSION}/Dockerfile

  # Dockerfile_spec.rb
  if [ ! -d "${MAJOR_VERSION}/inspec" ]; then
    mkdir "${MAJOR_VERSION}/inspec"
  fi

  sed 's#%%MYSQL_VERSION%%#'"${MYSQL_VERSION}"'#g' template/control.rb > tmpFile
  sed -i 's#%%MYSQL_SERVER_PACKAGE_NAME%%#'"${MYSQL_SERVER_PACKAGE_NAME}"'#g' tmpFile
  sed -i 's#%%MYSQL_SHELL_PACKAGE_NAME%%#'"${MYSQL_SHELL_PACKAGE_NAME}"'#g' tmpFile

  sed -i 's#%%MAJOR_VERSION%%#'"${MAJOR_VERSION}"'#g' tmpFile
  sed -i 's#%%MYSQL_SHELL_VERSION%%#'"${SHELL_VERSION}"'#g' tmpFile

  if [[ "${MAJOR_VERSION}" =~ 7\.(5|6) ]]; then
    sed -i 's#%%PORTS%%#'"1186/tcp, 2202/tcp, 3306/tcp, 33060/tcp"'#g' tmpFile
  else
    sed -i 's#%%PORTS%%#'"1186/tcp, 2202/tcp, 3306/tcp, 33060-33061/tcp"'#g' tmpFile
  fi
  mv tmpFile "${MAJOR_VERSION}/inspec/control.rb"

  # Entrypoint
  sed 's#%%PASSWORDSET%%#'"${PASSWORDSET[${MAJOR_VERSION}]}"'#g' template/docker-entrypoint.sh > tmpfile
  sed -i 's#%%STARTUP%%#'"${STARTUP[${MAJOR_VERSION}]}"'#g' tmpfile
  sed -i 's#%%FULL_SERVER_VERSION%%#'"${FULL_SERVER_VERSIONS[${MAJOR_VERSION}]}"'#g' tmpfile
  sed -i 's#%%VALIDATE_CONFIG%%#'"${VALIDATE_CONFIG[${MAJOR_VERSION}]}"'#g' tmpfile
  mv tmpfile ${MAJOR_VERSION}/docker-entrypoint.sh
  chmod +x ${MAJOR_VERSION}/docker-entrypoint.sh

  # Healthcheck
  cp template/healthcheck.sh ${MAJOR_VERSION}/
  chmod +x ${MAJOR_VERSION}/healthcheck.sh

  # Build-time preparation script
  sed 's#%%PRECREATE_DIRS%%#'"${PRECREATE_DIRS[${MAJOR_VERSION}]}"'#g' template/prepare-image.sh > tmpfile
  mv tmpfile ${MAJOR_VERSION}/prepare-image.sh
  chmod +x ${MAJOR_VERSION}/prepare-image.sh

  # Copy cnf files
  cp -r template/cnf ${MAJOR_VERSION}/
}

if [ -n "$MYSQL_VERSION" ]; then
  MAJOR_VERSION=$(echo $MYSQL_VERSION | cut -d'.' -f'1,2')
  SERVER_PKG_SUFFIX="-${MYSQL_VERSION}"
  SHELL_PKG_SUFFIX="-${SHELL_VERSION}"
  process_version $MAJOR_VERSION
else
  for MAJOR_VERSION in "${!MYSQL_CLUSTER_VERSIONS[@]}"
  do
    SHELL_VERSION="${MYSQL_SHELL_VERSIONS[$MAJOR_VERSION]}"
    SHELL_PKG_SUFFIX="-${SHELL_VERSION}"
    SERVER_PKG_SUFFIX="-${MYSQL_CLUSTER_VERSIONS[$MAJOR_VERSION]}"

    process_version $MAJOR_VERSION
  done
fi

