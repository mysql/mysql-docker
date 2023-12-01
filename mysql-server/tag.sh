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
set -e
source VERSION

SUFFIX='' [ -n "$1" ] && SUFFIX=$1
WEEKLY='' [ -n "$2" ] && WEEKLY=$2
MAJOR_VERSIONS=("${!MYSQL_SERVER_VERSIONS[@]}"); [ -n "$3" ] && MAJOR_VERSIONS=("${@:3}")

for MAJOR_VERSION in "${MAJOR_VERSIONS[@]}"; do
  if [ "$WEEKLY" == "1" ]; then
    SERVER_VERSION=${WEEKLY_SERVER_VERSIONS["${MAJOR_VERSION}"]}
  else
    SERVER_VERSION=${MYSQL_SERVER_VERSIONS["${MAJOR_VERSION}"]}
  fi
  MAJOR_VERSION=${SERVER_VERSION%.*}
  FULL_SERVER_VERSION="${SERVER_VERSION}-${IMAGE_VERSION}"
  TAGS="${MAJOR_VERSION}${SUFFIX} ${SERVER_VERSION}${SUFFIX} ${FULL_SERVER_VERSION}${SUFFIX}"
  if [[ "$MAJOR_VERSION" == "$LATEST" ]]; then
     TAGS="$TAGS latest${SUFFIX}"
  fi
  echo $TAGS
done
