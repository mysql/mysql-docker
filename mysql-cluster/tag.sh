#!/bin/bash
# Copyright (c) 2020, 2023, Oracle and/or its affiliates. All rights reserved.
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

MAJOR_VERSIONS=("${!MYSQL_CLUSTER_VERSIONS[@]}"); [ -n "$1" ] && MAJOR_VERSIONS=("${@:1}")

for MAJOR_VERSION in "${MAJOR_VERSIONS[@]}"; do
  TAGS="$MAJOR_VERSION ${MYSQL_CLUSTER_VERSIONS[$MAJOR_VERSION]} ${FULL_SERVER_VERSIONS[$MAJOR_VERSION]}"

  if [ "$MAJOR_VERSION" = "$LATEST" ]; then
    TAGS="latest $TAGS"
  fi

  echo $TAGS
done
