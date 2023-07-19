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

FROM container-registry.oracle.com/os/oraclelinux:8-slim

ARG MYSQL_SERVER_PACKAGE=mysql-community-server-minimal-8.1.0
ARG MYSQL_SHELL_PACKAGE=mysql-shell-8.1.0

# Setup repositories for minimal packages (all versions)
RUN rpm -U http://repo.mysql.oraclecorp.com/mysql-uat/repos-stage/mysql-community-minimal-release-el8.rpm \
  && rpm -U http://repo.mysql.oraclecorp.com/mysql-uat/repos-stage/mysql80-community-release-el8.rpm

# Install server and shell 8.0
RUN microdnf update && echo "[main]" > /etc/dnf/dnf.conf \
  && microdnf install -y --enablerepo=mysql-tools-innovation-community $MYSQL_SHELL_PACKAGE \
  && microdnf install -y --disablerepo=ol8_appstream \
   --enablerepo=mysql-innovation-community-minimal $MYSQL_SERVER_PACKAGE \
  && microdnf remove mysql-community-minimal-release mysql80-community-release \
  && microdnf clean all \
  && mkdir /docker-entrypoint-initdb.d

COPY prepare-image.sh /
RUN /prepare-image.sh && rm -f /prepare-image.sh

ENV MYSQL_UNIX_PORT /var/lib/mysql/mysql.sock

COPY docker-entrypoint.sh /entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
ENTRYPOINT ["/entrypoint.sh"]
HEALTHCHECK CMD /healthcheck.sh
EXPOSE 3306 33060 33061
CMD ["mysqld"]

