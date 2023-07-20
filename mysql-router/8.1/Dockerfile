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
FROM container-registry.oracle.com/os/oraclelinux:8-slim

ARG MYSQL_CLIENT_PACKAGE=mysql-community-client-8.1.0
ARG MYSQL_ROUTER_PACKAGE=mysql-router-community-8.1.0
ARG CONFIG_PACKAGE_NAME=mysql80-community-release-el8.rpm
ARG REPO_NAME_SERVER=mysql-innovation-community
ARG REPO_NAME_TOOLS=mysql-tools-innovation-community

RUN /usr/sbin/groupadd -g 999 -r mysqlrouter >/dev/null \
  && /usr/sbin/useradd -M -N -u 999 -g mysqlrouter -r -d /var/lib/mysqlrouter -s /bin/false \
      -c "MySQL Router" mysqlrouter \
  && rpm -U http://repo.mysql.oraclecorp.com/mysql-uat/repos-stage/$CONFIG_PACKAGE_NAME \
  && microdnf install -y --disablerepo=\* \
     --enablerepo=mysql-innovation-community $MYSQL_CLIENT_PACKAGE \
  && microdnf install -y --disablerepo=\* \
     --enablerepo=mysql-tools-innovation-community $MYSQL_ROUTER_PACKAGE \
  && microdnf clean all

COPY run.sh /run.sh
HEALTHCHECK \
	CMD mysqladmin --port 6446 --protocol TCP ping 2>&1 | grep Access || exit 1
EXPOSE 6446 6447 6448 6449 8443
USER 999:999
ENTRYPOINT ["/run.sh"]
CMD ["mysqlrouter"]
