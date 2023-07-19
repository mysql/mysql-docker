#!/bin/bash
# Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.
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

# This script will simply use sed to replace placeholder variables in the
# files in template/ with version-specific variants.
set -e
source ./VERSION

if grep -q Microsoft /proc/version; then
  echo "Running on Windows Subsystem for Linux"
  # WSL doesn't have its own docker host, we have to use the one 
  # from Windows itself.
  # https://medium.com/@sebagomez/installing-the-docker-client-on-ubuntus-windows-subsystem-for-linux-612b392a44c4
  export DOCKER_HOST=localhost:2375
  shopt -s expand_aliases
  alias inspec="cmd.exe /c C:/opscode/inspec/bin/inspec"
fi

ARCH=amd64; [ -n "$1" ] && ARCH=$1
BUILD_TYPE=community; [ -n "$2" ] && BUILD_TYPE=$2
MAJOR_VERSIONS=("${!MYSQL_SERVER_VERSIONS[@]}"); [ -n "$3" ] && MAJOR_VERSIONS=("${@:3}")

for MAJOR_VERSION in "${MAJOR_VERSIONS[@]}"; do
    if [[ ${BUILD_TYPE} =~ (commercial) ]]; then
      IMG_LOC="store/oracle/mysql-enterprise-server"
      CONT_NAME="mysql-enterprise-server-$MAJOR_VERSION"
    else
      IMG_LOC="mysql/mysql-server"
      CONT_NAME="mysql-server-$MAJOR_VERSION"
    fi
    ARCH_SUFFIX=""
    for MULTIARCH_VERSION in "${MULTIARCH_VERSIONS[@]}"; do
      if [[ "$MULTIARCH_VERSION" == "$MAJOR_VERSION" ]]; then
        ARCH_SUFFIX="-$ARCH"
      fi
    done
    podman run -d --rm --name $CONT_NAME "$IMG_LOC":"$MAJOR_VERSION$ARCH_SUFFIX"
    export DOCKER_HOST=unix:///tmp/podman.sock
    podman system service --time=0 ${DOCKER_HOST} & DOCKER_SOCK_PID="$!"
    inspec exec --no-color "$MAJOR_VERSION/inspec/control.rb" --controls container
    inspec exec --no-color "$MAJOR_VERSION/inspec/control.rb" -t "docker://$CONT_NAME" --controls packages
    podman stop -i "$CONT_NAME"
    podman rm -i -f "$CONT_NAME"
    kill -TERM ${DOCKER_SOCK_PID}
    rm -f /tmp/podman.sock
done
