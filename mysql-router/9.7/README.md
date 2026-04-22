![logo](https://www.mysql.com/common/logos/logo-mysql-170x115.png)

# What is MySQL Router?

MySQL Router is part of InnoDB cluster, and is lightweight middleware that
provides transparent routing between your application and back-end MySQL
Servers. It can be used for a wide variety of use cases, such as providing high
availability and scalability by effectively routing database traffic to
appropriate back-end MySQL Servers. The pluggable architecture also enables
developers to extend MySQL Router for custom use cases.

# Supported Tags and Respective Dockerfile Links

* MySQL Router 8.0 (tag: [`latest`, `8.0`](https://github.com/mysql/mysql-docker/blob/mysql-router/8.0/Dockerfile)) ([mysql-router/8.0/Dockerfile](https://github.com/mysql/mysql-docker/blob/mysql-router/8.0/Dockerfile))

Images are updated when new MySQL Server maintenance releases and development milestones are published. Please note that non-GA releases are for preview purposes only and should not be used in production setups.

# How to Use the MySQL Router Images

The image currently uses the following mandatory variables:

| Variable                 | Description                                 |
| ------------------------ | ------------------------------------------- |
| MYSQL_HOST               | MySQL host to connect to                    |
| MYSQL_PORT               | Port to use                                 |
| MYSQL_USER               | User to connect with                        |
| MYSQL_PASSWORD           | Password to connect with                    |

Running in a container requires a working InnoDB cluster.

The image uses the following optional variables:

| Variable                             | Description                                 |
| ------------------------------------ | ------------------------------------------- |
| MYSQL_INNODB_CLUSTER_MEMBERS         | Wait for at least this number of cluster instances to be ONLINE |
| MYSQL_CREATE_ROUTER_USER             | Whether to create a new account for the Router to use when it's running. Defaults to 1, set to 0 to disable. |
| MYSQL_ROUTER_BOOTSTRAP_EXTRA_OPTIONS | Additional command line options applied while bootstrapping

If supplied the run script waits for the given mysql host to be up, the InnoDB cluster to have
MYSQL_INNODB_CLUSTER_MEMBERS members and then uses the given server for its
bootstrap mode
[Bootstrapping](https://dev.mysql.com/doc/mysql-router/8.0/en/mysql-router-deploying-bootstrapping.html).

The image can be run via:

```
docker run -e MYSQL_HOST=localhost -e MYSQL_PORT=3306 -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -e MYSQL_INNODB_CLUSTER_MEMBERS=3 -ti mysql/mysql-router
```

Additional command line options for running MySQL Router after bootstrap can be passed a command options. For instance you can use a config file from your home directory like this:

```
docker run -e MYSQL_HOST=localhost -e MYSQL_PORT=3306 -e MYSQL_USER=mysql -e MYSQL_PASSWORD=mysql -ti -v $HOME/router-extra.conf:/tmp/router-extra.conf mysql/mysql-router mysqlrouter --extra-config=/tmp/router-extra.conf
```

It can be verified by typing:

```
docker ps
```

The following output should be displayed:

```
4954b1c80be1 mysql-router:8.0 "/run.sh mysqlrouter" About a minute ago Up About a minute (healthy) 6447/tcp, 6448/tcp, 0.0.0.0:6446->6446/tcp, 6449/tcp innodbcluster_mysql-router_1
```

By default the container will run as user 999:999 which maps to mysqlrouter:mysqlrouter inside the container.

# Exposed Ports

The following TCP ports are exposed by the MySQL Router container:

| Port  | Description
| ----- | --------------------------------------------------------------------------------------- |
| 6446  | R/W connection port. Clients that connect to this port will be forwarded to the PRIMARY |
| 6447  | R/O connection port. Clients that connect to this port will be forwarded to a SECONDARY |
| 6448  | X Protocol R/W connection port. R/W port for X protocol client connections              |
| 6449  | X Protocol R/O connection port. R/O port for X protocol client connections              |
| 8443  | HTTPS REST interface port.                                                              |

For more information about the REST interface API, see:

https://dev.mysql.com/doc/mysql-router/8.0/en/mysql-router-rest-api-reference.html

For full usage documentation, see:

https://dev.mysql.com/doc/mysql-router/8.0/en/mysql-router-installation-docker.html
