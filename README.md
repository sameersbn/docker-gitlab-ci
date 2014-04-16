# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
    - [Changelog](Changelog.md)
- [Supported Web Browsers](#supported-web-browsers)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Database](#database)
        - [MySQL](#mysql)
            - [Internal MySQL Server](#internal-mysql-server)
            - [External MySQL Server](#external-mysql-server)
            - [Linking to MySQL Container](#linking-to-mysql-container)
        - [PostgreSQL](#postgresql)
            - [External PostgreSQL Server](#external-postgresql-server)
            - [Linking to PostgreSQL Container](#linking-to-postgresql-container)
    - [Mail](#mail)
    - [Putting it all together](#putting-it-all-together)
    - [Available Configuration Parameters](#available-configuration-parameters)
- [Maintenance](#maintenance)
    - [SSH Login](#ssh-login)
- [Upgrading](#upgrading)
- [Issues](#issues)
- [References](#references)

# Introduction
Dockerfile to build a GitLab CI container image.

## Version
Current Version: 4.3.0

# Supported Web Browsers

- Chrome (Latest stable version)
- Firefox (Latest released version)
- Safari 7+ (Know problem: required fields in html5 do not work)
- Opera (Latest released version)
- IE 10+

# Installation

Pull the latest version of the image from the docker index. This is the recommended method of installation as it is easier to update image in the future. These builds are performed by the **Docker Trusted Build** service.

```bash
docker pull sameersbn/gitlab-ci:latest
```

Starting from GitLab CI version 4.3.0, You can pull a particular version of GitLab CI by specifying the version number. For example,

```bash
docker pull sameersbn/gitlab-ci:4.3.0
```

Alternately you can build the image yourself.

```bash
git clone https://github.com/sameersbn/docker-gitlab-ci.git
cd docker-gitlab-ci
docker build --tag="$USER/gitlab-ci" .
```

# Quick Start
Before you can start the GitLab CI image you need to make sure you have a [GitLab](https://www.gitlab.com/) server running. Checkout the [docker-gitlab](https://github.com/sameersbn/docker-gitlab) project for getting a GitLab server up and running.

You need to provide the URL of the GitLab server while running GitLab CI using the GITLAB_URL environment configuration. For example if the location of the GitLab server is 172.17.0.2

```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_URL=http://172.17.0.2" \
  sameersbn/gitlab-ci:latest
GITLAB_CI_IP=$(docker inspect gitlab-ci | grep IPAddres | awk -F'"' '{print $4}')
```

Alternately, if the GitLab and GitLab CI servers are running on the same host, you can take advantage of docker links. Lets consider that the GitLab server is running on the same host and has the name **"gitlab"**, then using docker links:

```bash
docker run --name=gitlab-ci -d -link gitlab:gitlab sameersbn/gitlab-ci:latest
GITLAB_CI_IP=$(docker inspect gitlab-ci | grep IPAddres | awk -F'"' '{print $4}')
```

Access the GitLab CI server

```bash
xdg-open "http://${GITLAB_CI_IP}"
```

Login using your GitLab credentials.

You should now have GitLab CI ready for testing. If you want to use GitLab CI for more than just testing then please read the **Advanced Options** section.

**PS:** You need to install [GitLab CI Runner](https://gitlab.com/gitlab-org/gitlab-ci-runner/blob/master/README.md) if you want to do anything worth while with the GitLab CI server. Please look up github / docker index service for runner containers.

# Configuration

## Database
GitLab CI uses a database backend to store its data.

### MySQL

#### Internal MySQL Server

> **Warning**
>
> The internal mysql server will soon be removed from the image.

> Please use a linked [mysql](#linking-to-mysql-container) or
> [postgresql](#linking-to-postgresql-container) container instead.
> Or else connect with an external [mysql](#external-mysql-server) or
> [postgresql](#external-postgresql-server) server.

> You've been warned.

This docker image is configured to use a MySQL database backend. The database connection can be configured using environment variables. If not specified, the image will start a mysql server internally and use it. However in this case, the data stored in the mysql database will be lost if the container is stopped/removed. To avoid this you should mount a volume at /var/lib/mysql.

```bash
mkdir /opt/gitlab-ci/mysql
docker run --name=gitlab-ci -d \
  -e "GITLAB_URL=http://172.17.0.2" \
  -v /opt/gitlab-ci/mysql:/var/lib/mysql sameersbn/gitlab-ci:latest
```

This will make sure that the data stored in the database is not lost when the image is stopped and started again.

#### External MySQL Server
The image can be configured to use an external MySQL database instead of starting a MySQL server internally. The database configuration should be specified using environment variables while starting the GitLab CI image.

Before you start the GitLab CI image create user and database for GitLab CI.

```sql
CREATE USER 'gitlab_ci'@'%.%.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `gitlab_ci_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlab_ci_production`.* TO 'gitlab_ci'@'%.%.%.%';
```

To make sure the database is initialized start the container with **app:rake db:setup** option.

*Assuming that the mysql server host is 192.168.1.100*

```bash
docker run --name=gitlab-ci -i -t --rm \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  sameersbn/gitlab-ci:latest app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

This will initialize the GitLab CI database. Now that the database is initialized, start the container normally.

```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  sameersbn/gitlab-ci:latest
```

#### Linking to MySQL Container
You can link this image with a mysql container for the database requirements. The alias of the mysql server container should be set to **mysql** while linking with the gitlab ci image.

If a mysql container is linked, only the DB_HOST and DB_PORT settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the DB_NAME, DB_USER, DB_PASS and so on.

To illustrate linking with a mysql container, we will use the [sameersbn/mysql](https://github.com/sameersbn/docker-mysql) image. When using docker-mysql in production you should mount a volume for the mysql data store. Please refer the [README](https://github.com/sameersbn/docker-mysql/blob/master/README.md) of docker-mysql for details.

First, lets pull the mysql image from the docker index.
```bash
docker pull sameersbn/mysql:latest
```

For data persistence lets create a store for the mysql and start the container.
```bash
mkdir -p /opt/mysql/data
docker run --name mysql -d \
  -v /opt/mysql/data:/var/lib/mysql \
  sameersbn/mysql:latest
```

You should now have the mysql server running. By default the sameersbn/mysql image does not assign a password for the root user and allows remote connections for the root user from the 172.17.%.% address space. This means you can login to the mysql server from the host as the root user.

Now, lets login to the mysql server and create a user and database for the GitLab application.

```bash
mysql -uroot -h $(docker inspect mysql | grep IPAddres | awk -F'"' '{print $4}')
```

```sql
CREATE USER 'gitlab_ci'@'%.%.%.%' IDENTIFIED BY 'password';
CREATE DATABASE IF NOT EXISTS `gitlab_ci_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;
GRANT SELECT, LOCK TABLES, INSERT, UPDATE, DELETE, CREATE, DROP, INDEX, ALTER ON `gitlab_ci_production`.* TO 'gitlab_ci'@'%.%.%.%';
FLUSH PRIVILEGES;
```

Now that we have the database created for GitLab CI, lets install the database schema. This is done by starting the gitlab container with the **app:rake db:setup** command.

```bash
docker run --name=gitlab-ci -i -t --rm --link mysql:mysql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "DB_NAME=gitlab_ci_production" \
  sameersbn/gitlab-ci:latest app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the GitLab application.

```bash
docker run --name=gitlab-ci -d --link mysql:mysql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "DB_NAME=gitlab_ci_production" \
  sameersbn/gitlab-ci:latest
```

### PostgreSQL

#### External PostgreSQL Server
The image also supports using an external PostgreSQL Server. This is also controlled via environment variables.

```sql
CREATE ROLE gitlab_ci with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE gitlab_ci_production;
GRANT ALL PRIVILEGES ON DATABASE gitlab_ci_production to gitlab_ci;
```

To make sure the database is initialized start the container with **app:rake db:setup** option.

*Assuming that the PostgreSQL server host is 192.168.1.100*

```bash
docker run --name=gitlab-ci -i -t --rm \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  sameersbn/gitlab-ci:latest app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

This will initialize the GitLab CI database. Now that the database is initialized, start the container normally.

```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  sameersbn/gitlab-ci:latest
```

#### Linking to PostgreSQL Container
You can link this image with a postgresql container for the database requirements. The alias of the postgresql server container should be set to **postgresql** while linking with the gitlab ci image.

If a postgresql container is linked, only the DB_HOST and DB_PORT settings are automatically retrieved using the linkage. You may still need to set other database connection parameters such as the DB_NAME, DB_USER, DB_PASS and so on.

To illustrate linking with a postgresql container, we will use the [sameersbn/postgresql](https://github.com/sameersbn/docker-postgresql) image. When using postgresql image in production you should mount a volume for the postgresql data store. Please refer the [README](https://github.com/sameersbn/docker-postgresql/blob/master/README.md) of docker-postgresql for details.

First, lets pull the postgresql image from the docker index.
```bash
docker pull sameersbn/postgresql:latest
```

For data persistence lets create a store for the postgresql and start the container.
```bash
mkdir -p /opt/postgresql/data
docker run --name postgresql -d \
  -v /opt/postgresql/data:/var/lib/postgresql \
  sameersbn/postgresql:latest
```

You should now have the postgresql server running. The password for the postgres user can be found in the logs of the postgresql image.

```bash
docker logs postgresql
```

Now, lets login to the postgresql server and create a user and database for the GitLab application.

```bash
POSTGRESQL_IP=$(docker inspect postgresql | grep IPAddres | awk -F'"' '{print $4}')
psql -U postgres -h ${POSTGRESQL_IP}
```

```sql
CREATE ROLE gitlab_ci with LOGIN CREATEDB PASSWORD 'password';
CREATE DATABASE gitlab_ci_production;
GRANT ALL PRIVILEGES ON DATABASE gitlab_ci_production to gitlab_ci;
```

Now that we have the database created for gitlab ci, lets install the database schema. This is done by starting the gitlab container with the **app:rake db:setup** command.

```bash
docker run --name=gitlab-ci -i -t --rm --link postgresql:postgresql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "DB_NAME=gitlab_ci_production" \
  sameersbn/gitlab-ci:latest app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the GitLab CI application.

```bash
docker run --name=gitlab-ci -d --link postgresql:postgresql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "DB_NAME=gitlab_ci_production" \
  sameersbn/gitlab-ci:latest
```

### Mail
The mail configuration should be specified using environment variables while starting the GitLab CI image. The configuration defaults to using gmail to send emails and requires the specification of a valid username and password to login to the gmail servers.

The following environment variables need to be specified to get mail support to work.

* SMTP_DOMAIN (defaults to www.gmail.com)
* SMTP_HOST (defaults to smtp.gmail.com)
* SMTP_PORT (defaults to 587)
* SMTP_USER
* SMTP_PASS
* SMTP_STARTTLS (defaults to true)
* SMTP_AUTHENTICATION (defaults to :login)

```bash
docker run --name=gitlab-ci -d \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/gitlab-ci:latest
```

Please look up the [Available Configuration Parameters](#available-configuration-parameters) section for all available SMTP configuration options.

### Putting it all together

```bash
docker run --name=gitlab-ci -d -h gitlab-ci.local.host \
  -v /opt/gitlab-ci/mysql:/var/lib/mysql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "GITLAB_CI_HOST=gitlab-ci.local.host" \
  -e "GITLAB_CI_EMAIL=gitlab@local.host" \
  -e "GITLAB_CI_SUPPORT=support@local.host" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/gitlab-ci:latest
```

If you are using an external mysql database

```bash
docker run --name=gitlab-ci -d -h gitlab-ci.local.host \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "GITLAB_CI_HOST=gitlab-ci.local.host" \
  -e "GITLAB_CI_EMAIL=gitlab@local.host" \
  -e "GITLAB_CI_SUPPORT=support@local.host" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/gitlab-ci:latest
```

### Available Configuration Parameters

Below is the complete list of available options that can be used to customize your GitLab CI installation.

- **GITLAB_URL**: Url of the GitLab server to allow connections from. No defaults. Automatically configured when a GitLab server is linked using docker links feature.
- **GITLAB_CI_HOST**: The hostname of the GitLab CI server. Defaults to localhost.
- **GITLAB_CI_PORT**: The port number of the GitLab CI server. Defaults to 80.
- **GITLAB_CI_EMAIL**: The email address for the GitLab CI server. Defaults to gitlab@localhost.
- **GITLAB_CI_SUPPORT**: The support email address for the GitLab CI server. Defaults to support@localhost.
- **REDIS_HOST**: The hostname of the redis server. Defaults to localhost
- **REDIS_PORT**: The connection port of the redis server. Defaults to 6379.
- **UNICORN_WORKERS**: The number of unicorn workers to start. Defaults to 2.
- **UNICORN_TIMEOUT**: Sets the timeout of unicorn worker processes. Defaults to 60 seconds.
- **DB_TYPE**: The database type. Possible values: mysql, postgres. Defaults to mysql.
- **DB_HOST**: The database server hostname. Defaults to localhost.
- **DB_PORT**: The database server port. Defaults to 3306 for mysql and 5432 for postgresql.
- **DB_NAME**: The database database name. Defaults to gitlab_ci_production
- **DB_USER**: The database database user. Defaults to root
- **DB_PASS**: The database database password. Defaults to no password
- **DB_POOL**: The database database connection pool count. Defaults to 10.
- **SMTP_DOMAIN**: SMTP domain. Defaults to www.gmail.com
- **SMTP_HOST**: SMTP server host. Defaults to smtp.gmail.com.
- **SMTP_PORT**: SMTP server port. Defaults to 587.
- **SMTP_USER**: SMTP username.
- **SMTP_PASS**: SMTP password.
- **SMTP_STARTTLS**: Enable STARTTLS. Defaults to true.
- **SMTP_AUTHENTICATION**: SMTP authentication mode. Defaults to :login.

# Maintenance

## SSH Login
There are two methods to gain root login to the container, the first method is to add your public rsa key to the authorized_keys file and build the image.

The second method is use the dynamically generated password. Every time the container is started a random password is generated using the pwgen tool and assigned to the root user. This password can be fetched from the docker logs.

```bash
docker logs gitlab-ci 2>&1 | grep '^User: ' | tail -n1
```

This password is not persistent and changes every time the image is executed.

# Upgrading

To upgrade to newer GitLab CI releases, simply follow this 4 step upgrade procedure.

- **Step 1**: Stop the currently running image

```bash
docker stop gitlab-ci
```

- **Step 2**: Update the docker image.

```bash
docker pull sameersbn/gitlab-ci:latest
```

- **Step 3**: Migrate the database.

```bash
docker run --name=gitlab-ci -i -t --rm [OPTIONS] \
  sameersbn/gitlab-ci:latest app:rake db:migrate
```

- **Step 4**: Start the image

```bash
docker run --name=gitlab-ci -d [OPTIONS] sameersbn/gitlab-ci:latest
```

# Issues
Please report issue [here](https://github.com/sameersbn/docker-gitlab-ci/issues)

# References
  * https://www.gitlab.com/gitlab-ci/
  * https://gitlab.com/gitlab-org/gitlab-ci/blob/master/README.md
