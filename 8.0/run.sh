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

if [ "$1" = 'mysqlrouter' ]; then
    if [[ -z $MYSQL_HOST || -z $MYSQL_PORT || -z $MYSQL_USER || -z $MYSQL_PASSWORD ]]; then
	    echo "We require all of"
	    echo "    MYSQL_HOST"
	    echo "    MYSQL_PORT"
	    echo "    MYSQL_USER"
	    echo "    MYSQL_PASSWORD"
	    echo "to be set. Exiting."
	    exit 1
    fi

    echo $MYSQL_PASSWORD > /tmp/mysqlrouter-pass
    unset MYSQL_PASSWORD
    max_tries=12
    attempt_num=0
    until (echo > "/dev/tcp/$MYSQL_HOST/$MYSQL_PORT") >/dev/null 2>&1; do
	    echo "Waiting for mysql server $MYSQL_HOST ($attempt_num/$max_tries)"
	    sleep $(( attempt_num++ ))
	    if (( attempt_num == max_tries )); then
		    exit 1
	    fi
    done
    echo "Succesfully contacted mysql server at $MYSQL_HOST. Checking for cluster state."
    if ! [[ "$(mysql -u "$MYSQL_USER" -p -h "$MYSQL_HOST" -P "$MYSQL_PORT" -e "show status;" < /tmp/mysqlrouter-pass 2> /dev/null)" ]]; then
	    echo "Can not connect to database. Exiting."
	    exit 1
    fi
    if [[ -n $MYSQL_INNODB_CLUSTER_MEMBERS ]]; then
      attempt_num=0
      until [ "$(mysql -u "$MYSQL_USER" -p -h "$MYSQL_HOST" -P "$MYSQL_PORT" -N performance_schema -e "select count(MEMBER_STATE) = $MYSQL_INNODB_NUM_MEMBERS from replication_group_members where MEMBER_STATE = 'ONLINE';" < /tmp/mysqlrouter-pass 2> /dev/null)" -eq 1 ]; do
             echo "Waiting for $MYSQL_INNODB_NUM_MEMBERS cluster instances to become available via $MYSQL_HOST ($attempt_num/$max_tries)"
             sleep $(( attempt_num++ ))
             if (( attempt_num == max_tries )); then
                     exit 1
             fi
      done
      echo "Succesfully contacted cluster with $MYSQL_INNODB_NUM_MEMBERS members. Bootstrapping."
    fi
    echo "Succesfully contacted mysql server at $MYSQL_HOST. Trying to bootstrap."
    mysqlrouter --bootstrap "$MYSQL_USER@$MYSQL_HOST:$MYSQL_PORT" --user=mysqlrouter --directory /tmp/mysqlrouter --force < /tmp/mysqlrouter-pass
    sed -i -e 's/logging_folder=.*$/logging_folder=/' /tmp/mysqlrouter/mysqlrouter.conf
    echo "Starting mysql-router."
    exec "$@" --config /tmp/mysqlrouter/mysqlrouter.conf
fi

exec "$@"
