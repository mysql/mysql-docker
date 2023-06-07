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
CONFIG_PACKAGE_NAME=mysql80-community-release-el8.rpm; [ -n "$2" ] && CONFIG_PACKAGE_NAME=$2
CONFIG_PACKAGE_NAME_MINIMAL=mysql-community-minimal-release-el8.rpm; [ -n "$3" ] && CONFIG_PACKAGE_NAME_MINIMAL=$3

REPO_NAME_SERVER=mysql80-community-minimal; [ -n "$4" ] && REPO_NAME_SERVER=$4
REPO_NAME_TOOLS=mysql-tools-community; [ -n "$5" ] && REPO_NAME_TOOLS=$5

MYSQL_SERVER_PACKAGE_NAME="mysql-community-server-minimal"; [ -n "$6" ] && MYSQL_SERVER_PACKAGE_NAME=$6
MYSQL_SHELL_PACKAGE_NAME="mysql-shell"; [ -n "$7" ] && MYSQL_SHELL_PACKAGE_NAME=$7
MYSQL_VERSION=""; [ -n "$8" ] && MYSQL_VERSION=$8
SHELL_VERSION=""; [ -n "$9" ] && SHELL_VERSION=$9
MYSQL_CONFIG_PKG_MINIMAL="mysql-community-minimal-release"; [ -n "${10}" ] && MYSQL_CONFIG_PKG_MINIMAL=${10}
MYSQL_CONFIG_PKG="mysql80-community-release"; [ -n "${11}" ] && MYSQL_CONFIG_PKG=${11}

if [[ ${MYSQL_CONFIG_PKG_MINIMAL} =~ (community) ]]; then
   CONT_NAME="mysql-server"
else
   CONT_NAME="mysql-enterprise-server"
fi

# 33060 is the default port for the mysqlx plugin, new to 5.7
declare -A PORTS
PORTS["5.7"]="3306 33060"
PORTS["8.0"]="3306 33060 33061"
PORTS["$LATEST_INNOVATION"]="3306 33060 33061"

declare -A PASSWORDSET
PASSWORDSET["5.7"]="ALTER USER 'root'@'localhost' IDENTIFIED BY '\${MYSQL_ROOT_PASSWORD}';"
PASSWORDSET["8.0"]=${PASSWORDSET["5.7"]}
PASSWORDSET["$LATEST_INNOVATION"]=${PASSWORDSET["8.0"]}

# MySQL 8.0 supports a call to validate the config, while older versions have it as a side
# effect of running --verbose --help
declare -A VALIDATE_CONFIG
VALIDATE_CONFIG["5.7"]="output=\$(\"\$@\" --verbose --help 2>\&1 > /dev/null) || result=\$?"
VALIDATE_CONFIG["8.0"]="output=\$(\"\$@\" --validate-config) || result=\$?"
VALIDATE_CONFIG["$LATEST_INNOVATION"]="output=\$(\"\$@\" --validate-config) || result=\$?"

# Data directories that must be created with special ownership and permissions when the image is built
declare -A PRECREATE_DIRS
PRECREATE_DIRS["5.7"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"
PRECREATE_DIRS["8.0"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"
PRECREATE_DIRS["$LATEST_INNOVATION"]="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"

declare -A DOCKERFILE_TEMPLATES
DOCKERFILE_TEMPLATES["5.7"]="template/Dockerfile-pre8"
DOCKERFILE_TEMPLATES["8.0"]="template/Dockerfile"
DOCKERFILE_TEMPLATES["$LATEST_INNOVATION"]="template/Dockerfile"

declare -A SPEC_PORTS
SPEC_PORTS["5.7"]="3306/tcp, 33060/tcp"
SPEC_PORTS["8.0"]="3306/tcp, 33060-33061/tcp"
SPEC_PORTS["$LATEST_INNOVATION"]="3306/tcp, 33060-33061/tcp"


# Get the Major Version
MAJOR_VERSION=$(echo $MYSQL_VERSION | cut -d'.' -f'1,2')
if [[ $(awk -v ver="$MAJOR_VERSION" 'BEGIN{ if (ver >= 8.1) print "true" }') == "true" ]]; then
        REPO_PATH="innovation"
fi

if [ ! -d "${MAJOR_VERSION}" ]; then
  mkdir -p "${MAJOR_VERSION}/inspec"
fi

MYSQL_SERVER_PACKAGE=${MYSQL_SERVER_PACKAGE_NAME}-${MYSQL_VERSION}
MYSQL_SHELL_PACKAGE=${MYSQL_SHELL_PACKAGE_NAME}-${SHELL_VERSION}

# Dockerfiles
sed 's#%%MYSQL_SERVER_PACKAGE%%#'"${MYSQL_SERVER_PACKAGE}"'#g' ${DOCKERFILE_TEMPLATES[${MAJOR_VERSION}]} > tmpfile
sed -i 's#%%REPO%%#'"${REPO}"'#g' tmpfile
sed -i 's#%%CONFIG_PACKAGE_NAME%%#'"${CONFIG_PACKAGE_NAME}"'#g' tmpfile
sed -i 's#%%CONFIG_PACKAGE_NAME_MINIMAL%%#'"${CONFIG_PACKAGE_NAME_MINIMAL}"'#g' tmpfile
sed -i 's#%%REPO_NAME_SERVER%%#'"${REPO_NAME_SERVER}"'#g' tmpfile
sed -i 's#%%REPO_NAME_TOOLS%%#'"${REPO_NAME_TOOLS}"'#g' tmpfile

sed -i 's#%%MYSQL_SHELL_PACKAGE%%#'"${MYSQL_SHELL_PACKAGE}"'#g' tmpfile

sed -i 's#%%MYSQL_CONFIG_PKG_MINIMAL%%#'"${MYSQL_CONFIG_PKG_MINIMAL}"'#g' tmpfile
sed -i 's#%%MYSQL_CONFIG_PKG%%#'"${MYSQL_CONFIG_PKG}"'#g' tmpfile

sed -i 's/%%PORTS%%/'"${PORTS[${MAJOR_VERSION}]}"'/g' tmpfile
mv tmpfile ${MAJOR_VERSION}/Dockerfile

# Dockerfile_spec.rb
sed 's#%%MYSQL_SERVER_VERSION%%#'"${MYSQL_VERSION}"'#g' template/control.rb > tmpFile
sed -i 's#%%MYSQL_SHELL_VERSION%%#'"${SHELL_VERSION}"'#g' tmpFile
sed -i 's#%%MYSQL_SERVER_PACKAGE_NAME%%#'"${MYSQL_SERVER_PACKAGE_NAME}"'#g' tmpFile
sed -i 's#%%MYSQL_SHELL_PACKAGE_NAME%%#'"${MYSQL_SHELL_PACKAGE_NAME}"'#g' tmpFile
sed -i 's#%%MAJOR_VERSION%%#'"${MAJOR_VERSION}"'#g' tmpFile
sed -i 's#%%CONT_NAME%%#'"${CONT_NAME}"'#g' tmpFile
sed -i 's#%%PORTS%%#'"${SPEC_PORTS[${MAJOR_VERSION}]}"'#g' tmpFile
mv tmpFile "${MAJOR_VERSION}/inspec/control.rb"

# Entrypoint
FULL_SERVER_VERSION="$MYSQL_VERSION-${IMAGE_VERSION}"
sed 's#%%PASSWORDSET%%#'"${PASSWORDSET[${MAJOR_VERSION}]}"'#g' template/docker-entrypoint.sh > tmpfile
sed -i 's#%%FULL_SERVER_VERSION%%#'"${FULL_SERVER_VERSION}"'#g' tmpfile
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
