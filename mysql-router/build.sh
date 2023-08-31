#!/bin/bash
# Copyright (c) 2018, 2023 Oracle and/or its affiliates. All rights reserved.
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
source ./VERSION

ARCH=amd64; [ -n "$1" ] && ARCH=$1
WEEKLY=''; [ -n "$2" ] && WEEKLY=$2
MAJOR_VERSIONS=("${!MYSQL_ROUTER_VERSIONS[@]}"); [ -n "$3" ] && MAJOR_VERSIONS=("${@:3}")

for MAJOR_VERSION in "${MAJOR_VERSIONS[@]}"; do
  if [ "$WEEKLY" == "1" ]; then
    ROUTER_VERSION=${WEEKLY_ROUTER_VERSIONS["${MAJOR_VERSION}"]}
  else
    ROUTER_VERSION=${MYSQL_ROUTER_VERSIONS["${MAJOR_VERSION}"]}
  fi
  MAJOR_VERSION=${ROUTER_VERSION%.*}
  docker build --build-arg http_proxy=$http_proxy --build-arg https_proxy=$http_proxy --build-arg no_proxy=$no_proxy -t mysql/mysql-router:$MAJOR_VERSION-$ARCH $MAJOR_VERSION
done
