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
FROM oraclelinux:7-slim

ARG MYSQL_SERVER_PACKAGE=mysql-community-server-minimal-5.7.39
ARG MYSQL_SHELL_PACKAGE=mysql-shell-8.0.30

# Setup repositories for minimal packages (all versions)
RUN rpm -U https://repo.mysql.com/mysql-community-minimal-release-el7.rpm \
  && rpm -U https://repo.mysql.com/mysql80-community-release-el7.rpm

# Install server and shell 8.0
RUN yum install -y $MYSQL_SHELL_PACKAGE \
  && yum install -y $MYSQL_SERVER_PACKAGE --enablerepo=mysql57-server-minimal\
  && yum clean all \
  && mkdir /docker-entrypoint-initdb.d

# Ensure mysqld logs go to stderr
RUN sed -i 's/^log-error=/#&/' /etc/my.cnf

COPY prepare-image.sh /
RUN /prepare-image.sh && rm -f /prepare-image.sh

ENV MYSQL_UNIX_PORT /var/lib/mysql/mysql.sock

COPY docker-entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK CMD /healthcheck.sh

USER mysql
EXPOSE 3306 33060
CMD ["mysqld"]

