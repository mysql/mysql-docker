#!/bin/bash
# Copyright (c) 2017, 2021, Oracle and/or its affiliates.
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

echo "[Entrypoint] MySQL Docker Image 8.0.42-1.2.21-cluster"
# Fetch value from server config
# We use mysqld --verbose --help instead of my_print_defaults because the
# latter only show values present in config files, and not server defaults
_get_config() {
	local conf="$1"; shift
	"$@" --verbose --help 2>/dev/null | grep "^$conf" | awk '$1 == "'"$conf"'" { print $2; exit }'
}

# Generate a random password
_mkpw() {
	letter=$(cat /dev/urandom| tr -dc a-zA-Z | dd bs=1 count=16 2> /dev/null )
	number=$(cat /dev/urandom| tr -dc 0-9 | dd bs=1 count=8 2> /dev/null)
	special=$(cat /dev/urandom| tr -dc '=+@#%^&*_.,;:?/' | dd bs=1 count=8 2> /dev/null)

	echo $letter$number$special | fold -w 1 | shuf | tr -d '\n'
}

# If command starts with an option, prepend mysqld
# This allows users to add command-line options without
# needing to specify the "mysqld" command
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

# Check if entrypoint (and the container) is running as root
if [ $(id -u) = "0" ]; then
	is_root=1
	install_devnull="install /dev/null -m0600 -omysql -gmysql"
	MYSQLD_USER=mysql
else
	install_devnull="install /dev/null -m0600"
	MYSQLD_USER=$(id -u)
fi

if [ "$1" = 'mysqld' ]; then
	# Test that the server can start. We redirect stdout to /dev/null so
	# only the error messages are left.
	result=0
	output=$("$@" --validate-config) || result=$?
	if [ ! "$result" = "0" ]; then
		echo >&2 '[Entrypoint] ERROR: Unable to start MySQL. Please check your configuration.'
		echo >&2 "[Entrypoint] $output"
		exit 1
	fi

	# Get config
	DATADIR="$(_get_config 'datadir' "$@")"
	SOCKET="$(_get_config 'socket' "$@")"

	if [ ! -d "$DATADIR/mysql" ]; then
		# If the password variable is a filename we use the contents of the file. We
		# read this first to make sure that a proper error is generated for empty files.
		if [ -f "$MYSQL_ROOT_PASSWORD" ]; then
			MYSQL_ROOT_PASSWORD="$(cat $MYSQL_ROOT_PASSWORD)"
			if [ -z "$MYSQL_ROOT_PASSWORD" ]; then
				echo >&2 '[Entrypoint] Empty MYSQL_ROOT_PASSWORD file specified.'
				exit 1
			fi
		fi
		if [ -z "$MYSQL_ROOT_PASSWORD" -a -z "$MYSQL_ALLOW_EMPTY_PASSWORD" -a -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
			echo >&2 '[Entrypoint] No password option specified for new database.'
			echo >&2 '[Entrypoint]   A random onetime password will be generated.'
			MYSQL_RANDOM_ROOT_PASSWORD=true
			MYSQL_ONETIME_PASSWORD=true
		fi
		if [ ! -d "$DATADIR" ]; then
			mkdir -p "$DATADIR"
			chown mysql:mysql "$DATADIR"
		fi

		# The user can set a default_timezone either in a my.cnf file
		# they mount into the container or on command line
		# (`docker run mysql/mysql-server:8.0 --default-time-zone=Europe/Berlin`)
		# however the timezone tables will only be populated in a later
		# stage of this script. By using +00:00 as timezone we override
		# the user's choice during initialization. Later the server
		# will be restarted using the user's option.

		echo '[Entrypoint] Initializing database'
		"$@" --user=$MYSQLD_USER --initialize-insecure  --default-time-zone=+00:00

		echo '[Entrypoint] Database initialized'
		"$@" --user=$MYSQLD_USER --daemonize --skip-networking --socket="$SOCKET" --default-time-zone=+00:00

		# To avoid using password on commandline, put it in a temporary file.
		# The file is only populated when and if the root password is set.
		PASSFILE=$(mktemp -u /var/lib/mysql-files/XXXXXXXXXX)
		$install_devnull "$PASSFILE"
		# Define the client command used throughout the script
		# "SET @@SESSION.SQL_LOG_BIN=0;" is required for products like group replication to work properly
		mysql=( mysql --defaults-extra-file="$PASSFILE" --protocol=socket -uroot -hlocalhost --socket="$SOCKET" --init-command="SET @@SESSION.SQL_LOG_BIN=0;")

		if [ ! -z %%STARTUP_WAIT%% ];
		then
			for i in {30..0}; do
				if mysqladmin --socket="$SOCKET" ping &>/dev/null; then
					break
				fi
				echo '[Entrypoint] Waiting for server...'
				sleep 1
			done
			if [ "$i" = 0 ]; then
				echo >&2 '[Entrypoint] Timeout during MySQL init.'
				exit 1
			fi
		fi

		mysql_tzinfo_to_sql /usr/share/zoneinfo | "${mysql[@]}" mysql

		if [ ! -z "$MYSQL_RANDOM_ROOT_PASSWORD" ]; then
			MYSQL_ROOT_PASSWORD="$(_mkpw)"
			echo "[Entrypoint] GENERATED ROOT PASSWORD: $MYSQL_ROOT_PASSWORD"
		fi
		if [ -z "$MYSQL_ROOT_HOST" ]; then
			ROOTCREATE="ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';"
		else
			ROOTCREATE="ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; \
			CREATE USER 'root'@'${MYSQL_ROOT_HOST}' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}'; \
			GRANT ALL ON *.* TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ; \
			GRANT PROXY ON ''@'' TO 'root'@'${MYSQL_ROOT_HOST}' WITH GRANT OPTION ;"
		fi
		"${mysql[@]}" <<-EOSQL
			DELETE FROM mysql.user WHERE user NOT IN ('mysql.infoschema', 'mysql.session', 'mysql.sys', 'root') OR host NOT IN ('localhost');
			CREATE USER 'healthchecker'@'localhost' IDENTIFIED BY 'healthcheckpass';
			${ROOTCREATE}
			FLUSH PRIVILEGES ;
		EOSQL
		if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
			# Put the password into the temporary config file
			cat >"$PASSFILE" <<EOF
[client]
password="${MYSQL_ROOT_PASSWORD}"
EOF
			#mysql+=( -p"${MYSQL_ROOT_PASSWORD}" )
		fi

		if [ "$MYSQL_DATABASE" ]; then
			echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql[@]}"
			mysql+=( "$MYSQL_DATABASE" )
		fi

		if [ "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo "CREATE USER '"$MYSQL_USER"'@'%' IDENTIFIED BY '"$MYSQL_PASSWORD"' ;" | "${mysql[@]}"

			if [ "$MYSQL_DATABASE" ]; then
				echo "GRANT ALL ON \`"$MYSQL_DATABASE"\`.* TO '"$MYSQL_USER"'@'%' ;" | "${mysql[@]}"
			fi

		elif [ "$MYSQL_USER" -a ! "$MYSQL_PASSWORD" -o ! "$MYSQL_USER" -a "$MYSQL_PASSWORD" ]; then
			echo '[Entrypoint] Not creating mysql user. MYSQL_USER and MYSQL_PASSWORD must be specified to create a mysql user.'
		fi
		echo
		for f in /docker-entrypoint-initdb.d/*; do
			case "$f" in
				*.sh)  echo "[Entrypoint] running $f"; . "$f" ;;
				*.sql) echo "[Entrypoint] running $f"; "${mysql[@]}" < "$f" && echo ;;
				*)     echo "[Entrypoint] ignoring $f" ;;
			esac
			echo
		done

		# When using a local socket, mysqladmin shutdown will only complete when the server is actually down
		mysqladmin --defaults-extra-file="$PASSFILE" shutdown -uroot --socket="$SOCKET"
		rm -f "$PASSFILE"
		unset PASSFILE
		echo "[Entrypoint] Server shut down"

		# This needs to be done outside the normal init, since mysqladmin shutdown will not work after
		if [ ! -z "$MYSQL_ONETIME_PASSWORD" ]; then
			if [ -z %%EXPIRE_SUPPORT%% ]; then
				echo "[Entrypoint] User expiration is only supported in MySQL 5.6+"
			else
				echo "[Entrypoint] Setting root user as expired. Password will need to be changed before database can be used."
				SQL=$(mktemp -u /var/lib/mysql-files/XXXXXXXXXX)
				$install_devnull "$SQL"
				if [ ! -z "$MYSQL_ROOT_HOST" ]; then
					cat << EOF > "$SQL"
ALTER USER 'root'@'${MYSQL_ROOT_HOST}' PASSWORD EXPIRE;
ALTER USER 'root'@'localhost' PASSWORD EXPIRE;
EOF
				else
					cat << EOF > "$SQL"
ALTER USER 'root'@'localhost' PASSWORD EXPIRE;
EOF
				fi
				set -- "$@" --init-file="$SQL"
				unset SQL
			fi
		fi

		echo
		echo '[Entrypoint] MySQL init process done. Ready for start up.'
		echo
	fi

	# Used by healthcheck to make sure it doesn't mistakenly report container
	# healthy during startup
	# Put the password into the temporary config file
	touch /var/lib/mysql-files/healthcheck.cnf
	cat >"/var/lib/mysql-files/healthcheck.cnf" <<EOF
[client]
user=healthchecker
socket=${SOCKET}
password=healthcheckpass
EOF
	touch /var/lib/mysql-files/mysql-init-complete

	if [ -n "$MYSQL_INITIALIZE_ONLY" ]; then
		echo "[Entrypoint] MYSQL_INITIALIZE_ONLY is set, exiting without starting MySQL..."
		exit 0
	else
		echo "[Entrypoint] Starting MySQL 8.0.42-1.2.21-cluster"
	fi
	export MYSQLD_PARENT_PID=$$ ; exec "$@" --user=
else
	if [ -n "$MYSQL_INITIALIZE_ONLY" ]; then
		echo "[Entrypoint] MySQL already initialized and MYSQL_INITIALIZE_ONLY is set, exiting without starting MySQL..."
		exit 0
	fi
	if [ "$1" == "ndb_mgmd" ]; then
		echo "[Entrypoint] Starting ndb_mgmd"
		set -- "$@" -f /etc/mysql-cluster.cnf --nodaemon

	elif [ "$1" == "ndbd" ]; then
		echo "[Entrypoint] Starting ndbd"
		set -- "$@" --nodaemon

	elif [ "$1" == "ndbmtd" ]; then
		echo "[Entrypoint] Starting ndbmtd"
		set -- "$@" --nodaemon

	elif [ "$1" == "ndb_mgm" ]; then
		echo "[Entrypoint] Starting ndb_mgm"

	elif [ "$1" == "ndb_waiter" ]; then
		if [ "%%NDBWAITER%%" == "yes" ]; then
			echo "[Entrypoint] Starting ndb_waiter"
			set -- "$@" --nodaemon
		else
			echo "[Entrypoint] ndb_waiter not supported"
			exit 1
		fi
	fi
	exec "$@"
fi

