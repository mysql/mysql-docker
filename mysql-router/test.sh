#!/bin/bash
# Copyright (c) 2018, 2023, Oracle and/or its affiliates.
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

ARCH=amd64; [ -n "$1" ] && ARCH=$1
MAJOR_VERSIONS=("${!MYSQL_SERVER_VERSIONS[@]}"); [ -n "$2" ] && MAJOR_VERSIONS=("${@:2}")

for MAJOR_VERSION in "${MAJOR_VERSIONS[@]}"; do
   podman run -d --rm -e MYSQL_HOST=x -e MYSQL_PORT=9 -e MYSQL_USER=x -e MYSQL_PASSWORD=x -e MYSQL_INNODB_CLUSTER_MEMBERS=1 --name "mysql-router-$MAJOR_VERSION" mysql/mysql-router:$MAJOR_VERSION-$ARCH sleep 5000
   export DOCKER_HOST=unix:///tmp/podman.sock
   podman system service --time=0 ${DOCKER_HOST} & DOCKER_SOCK_PID="$!"
   inspec exec $MAJOR_VERSION/inspec/control.rb --controls container
   inspec exec $MAJOR_VERSION/inspec/control.rb -t "docker://mysql-router-$MAJOR_VERSION" --controls packages
   podman stop -i "mysql-router-$MAJOR_VERSION"
   podman rm -i -f "mysql-router-$MAJOR_VERSION"
   kill -TERM ${DOCKER_SOCK_PID}
   rm -f /tmp/podman.sock
done
