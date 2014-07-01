# Table of Contents
- [Introduction](#introduction)
    - [Version](#version)
    - [Changelog](Changelog.md)
- [Supported Web Browsers](#supported-web-browsers)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
    - [Data Store](#data-store)
    - [Database](#database)
        - [MySQL](#mysql)
            - [Internal MySQL Server](#internal-mysql-server)
            - [External MySQL Server](#external-mysql-server)
            - [Linking to MySQL Container](#linking-to-mysql-container)
        - [PostgreSQL (Recommended)](#postgresql)
            - [External PostgreSQL Server](#external-postgresql-server)
            - [Linking to PostgreSQL Container](#linking-to-postgresql-container)
    - [Redis](#redis)
      - [Internal Redis Server](#internal-redis-server)
      - [External Redis Server](#external-redis-server)
      - [Linking to Redis Container](#linking-to-redis-container)
    - [Mail](#mail)
    - [SSL](#ssl)
      - [Generation of Self Signed Certificates](#generation-of-self-signed-certificates)
      - [Strengthening the server security](#strengthening-the-server-security)
      - [Installation of the Certificates](#installation-of-the-certificates)
      - [Enabling HTTPS support](#enabling-https-support)
      - [Using HTTPS with a load balancer](#using-https-with-a-load-balancer)
      - [Establishing trust with your server](#establishing-trust-with-your-server)
      - [Installing Trusted SSL Server Certificates](#installing-trusted-ssl-server-certificates)
    - [Putting it all together](#putting-it-all-together)
    - [Available Configuration Parameters](#available-configuration-parameters)
- [Maintenance](#maintenance)
- [Upgrading](#upgrading)
- Links
  - [Announcements](https://github.com/sameersbn/docker-gitlab-ci/issues/1)
  - [Issues](https://github.com/sameersbn/docker-gitlab-ci/issues)
- [References](#references)

# Introduction
Dockerfile to build a GitLab CI container image.

## Version
Current Version: 5.0.1

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

Starting from GitLab CI version 5.0.1, You can pull a particular version of GitLab CI by specifying the version number. For example,

```bash
docker pull sameersbn/gitlab-ci:5.0.1
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
  sameersbn/gitlab-ci:5.0.1
GITLAB_CI_IP=$(docker inspect gitlab-ci | grep IPAddres | awk -F'"' '{print $4}')
```

Alternately, if the GitLab and GitLab CI servers are running on the same host, you can take advantage of docker links. Lets consider that the GitLab server is running on the same host and has the name **"gitlab"**, then using docker links:

```bash
docker run --name=gitlab-ci -d -link gitlab:gitlab sameersbn/gitlab-ci:5.0.1
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

## Data Store
For storage of the application data, you should mount a volume at

* /home/gitlab_ci/data

Volumes can be mounted in docker by specifying the **'-v'** option in the docker run command.

```bash
mkdir -p /opt/gitlab-ci/data
docker run --name=gitlab-ci -d \
  -v /opt/gitlab-ci/data:/home/gitlab_ci/data \
  sameersbn/gitlab-ci:5.0.1
```

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
  -v /opt/gitlab-ci/mysql:/var/lib/mysql sameersbn/gitlab-ci:5.0.1
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
  sameersbn/gitlab-ci:5.0.1 app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

This will initialize the GitLab CI database. Now that the database is initialized, start the container normally.

```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  sameersbn/gitlab-ci:5.0.1
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
  sameersbn/gitlab-ci:5.0.1 app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the GitLab application.

```bash
docker run --name=gitlab-ci -d --link mysql:mysql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "DB_NAME=gitlab_ci_production" \
  sameersbn/gitlab-ci:5.0.1
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
  sameersbn/gitlab-ci:5.0.1 app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

This will initialize the GitLab CI database. Now that the database is initialized, start the container normally.

```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_TYPE=postgres" -e "DB_HOST=192.168.1.100" \
  -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  sameersbn/gitlab-ci:5.0.1
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
  sameersbn/gitlab-ci:5.0.1 app:rake db:setup
```

**NOTE: The above setup is performed only for the first run**.

We are now ready to start the GitLab CI application.

```bash
docker run --name=gitlab-ci -d --link postgresql:postgresql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "DB_NAME=gitlab_ci_production" \
  sameersbn/gitlab-ci:5.0.1
```

## Redis

### Internal Redis Server

> **Warning**
>
> The internal redis server will soon be removed from the image.

> Please use a linked [redis](#linking-to-redis-container) container
> or a external [redis](#external-redis-server) server

> You've been warned.

GitLab CI uses the redis server for its key-value data store. The redis server connection details can be specified using environment variables. If not specified, the  starts a redis server internally, no additional configuration is required.

### External Redis Server
The image can be configured to use an external redis server instead of starting a redis server internally. The configuration should be specified using environment variables while starting the GitLab CI image.

*Assuming that the redis server host is 192.168.1.100*

```bash
docker run --name=gitlab-ci -i -t --rm \
  -e "REDIS_HOST=192.168.1.100" -e "REDIS_PORT=6379" \
  sameersbn/gitlab-ci:5.0.1
```

### Linking to Redis Container
You can link this image with a redis container to satisfy GitLab CI's redis requirement. The alias of the redis server container should be set to **redisio** while linking with the GitLab image.

To illustrate linking with a redis container, we will use the [sameersbn/redis](https://github.com/sameersbn/docker-redis) image. Please refer the [README](https://github.com/sameersbn/docker-redis/blob/master/README.md) of docker-redis for details.

First, lets pull the redis image from the docker index.
```bash
docker pull sameersbn/redis:latest
```

Lets start the redis container
```bash
docker run --name=redis -d sameersbn/redis:latest
```

We are now ready to start the GitLab CI application.

```bash
docker run --name=gitlab-ci -d --link redis:redisio \
  sameersbn/gitlab:latest
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
  sameersbn/gitlab-ci:5.0.1
```

Please look up the [Available Configuration Parameters](#available-configuration-parameters) section for all available SMTP configuration options.

### SSL
Access to the gitlab ci application can be secured using SSL so as to prevent unauthorized access to the data in your repositories. While a CA certified SSL certificate allows for verification of trust via the CA, a self signed certificates can also provide an equal level of trust verification as long as each client takes some additional steps to verify the identity of your website. I will provide instructions on achieving this towards the end of this section.

To secure your application via SSL you basically need two things:
- Private key (.key)
- SSL certificate (.crt)

When using CA certified certificates, these files are provided to you by the CA. When using self-signed certificates you need to generate these files yourself. Skip the following section if you are armed with CA certified SSL certificates.

Jump to the [Strengthening the server security](#strengthening-the-server-security) section if you are using a load balancer such as hipache, haproxy or nginx.

#### Generation of Self Signed Certificates
Generation of self-signed SSL certificates involves a simple 3 step procedure.

**STEP 1**: Create the server private key
```bash
openssl genrsa -out gitlab_ci.key 2048
```

**STEP 2**: Create the certificate signing request (CSR)
```bash
openssl req -new -key gitlab_ci.key -out gitlab_ci.csr
```

**STEP 3**: Sign the certificate using the private key and CSR
```bash
openssl x509 -req -days 365 -in gitlab_ci.csr -signkey gitlab_ci.key -out gitlab_ci.crt
```

Congratulations! you have now generated an SSL certificate thats valid for 365 days.

#### Strengthening the server security
This section provides you with instructions to [strengthen your server security](https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html). To achieve this we need to generate stronger DHE parameters.

```bash
openssl dhparam -out dhparam.pem 2048
```

#### Installation of the SSL Certificates
Out of the four files generated above, we need to install the gitlab_ci.key, gitlab_ci.crt and dhparam.pem files at the gitlab ci server. The CSR file is not needed, but do make sure you safely backup the file (in case you ever need it again).

The default path that the gitlab ci application is configured to look for the SSL certificates is at /home/gitlab_ci/data/certs, this can however be changed using the SSL_KEY_PATH, SSL_CERTIFICATE_PATH and SSL_DHPARAM_PATH configuration options.

If you remember from above, the /home/gitlab_ci/data path is the path of the [data store](#data-store), which means that we have to create a folder named certs inside /opt/gitlab-ci/data and copy the files into it and as a measure of security we will update the permission on the gitlab_ci.key file to only be readable by the owner.

```bash
mkdir -p /opt/gitlab-ci/data/certs
cp gitlab_ci.key /opt/gitlab-ci/data/certs/
cp gitlab_ci.crt /opt/gitlab-ci/data/certs/
cp dhparam.pem /opt/gitlab-ci/data/certs/
chmod 400 /opt/gitlab-ci/data/certs/gitlab_ci.key
```

Great! we are now just a step away from having our application secured.

#### Enabling HTTPS support
HTTPS support can be enabled by setting the GITLAB_CI_HTTPS option to true.

```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_CI_HTTPS=true" \
  -v /opt/gitlab-ci/data:/home/gitlab_ci/data \
  sameersbn/gitlab-ci:5.0.1
```

In this configuration, any requests made over the plain http protocol will automatically be redirected to use the https protocol. However, this is not optimal when using a load balancer.

#### Using HTTPS with a load balancer
Load balancers like haproxy/hipache talk to backend applications over plain http and as such, installation of ssl keys and certificates in the container are not required when using a load balancer.

When using a load balancer, you should set the GITLAB_CI_HTTPS_ONLY option to false and the GITLAB_CI_HTTPS options set to true. With this in place, you should also configure the load balancer to support handling of https requests. But that is out of the scope of this document. Please refer to [Using SSL/HTTPS with HAProxy](http://seanmcgary.com/posts/using-sslhttps-with-haproxy) for information on the subject.

Note that when the GITLAB_CI_HTTPS_ONLY is disabled, the application does not perform the automatic http to https redirection and this functionality has to be configured at the load balancer which is also described in the link above. Unfortunately hipache does not come with an option to perform http to https redirection, so the only choice you really have is to switch to using haproxy or nginx for load balancing.

P.S. I have noticed problems in issuing builds from the GitLab interface when automatic http to https redirection is enabled on haproxy.

In summation, the docker command would look something like this:
```bash
docker run --name=gitlab-ci -d \
  -e "GITLAB_CI_HTTPS=true" \
  -e "GITLAB_CI_HTTPS_ONLY=false" \
  -v /opt/gitlab-ci/data:/home/gitlab_ci/data \
  sameersbn/gitlab-ci:5.0.1
```

#### Establishing trust with your server
This section deals will self-signed ssl certificates. If you are using CA certified certificates, your done.

This section is more of a client side configuration so as to add a level of confidence at the client to be 100 percent sure they are communicating with whom they think they.

This is simply done by adding the servers certificate into their list of trusted ceritficates. On ubuntu, this is done by appending the contents of the gitlab.crt file to the ```/etc/ssl/certs/ca-certificates.crt``` file.

Again, this is a client side configuration which means that everyone who is going to communicate with the server should perform this configuration on their machine. In short, distribute the gitlab_ci.crt file among your developers and ask them to add it to their list of trusted ssl certificates.

You can do the same at the web browser. Instructions for installing the root certificate for firefox can be found [here](http://portal.threatpulse.com/docs/sol/Content/03Solutions/ManagePolicy/SSL/ssl_firefox_cert_ta.htm). You will find similar options chrome, just make sure you install the certificate under the authorities tab of the certificate manager dialog.

There you have it, thats all there is to it.

#### Installing Trusted SSL Server Certificates
If your GitLab server is using self-signed SSL certificates then you should make sure the GitLab server certificate is trusted on the GitLab CI server for them to be able to talk to each other.

The default path image is configured to look for the trusted SSL certificates is at /home/gitlab_ci/data/certs/ca.crt, this can however be changed using the CA_CERTIFICATES_PATH configuration option.

Copy the ca.crt file into the certs directory on the [datastore](#data-store). The ca.crt file should contain the root certificates of all the servers you want to trust. With respect to GitLab, this will be the contents of the gitlab.crt file as described in the [README](https://github.com/sameersbn/docker-gitlab/blob/master/README.md#ssl) of the [docker-gitlab](https://github.com/sameersbn/docker-gitlab) container.

By default, our own server certificate [gitlab_ci.crt](#generation-of-self-signed-certificates) is added to the trusted certificates list.

### Putting it all together

```bash
docker run --name=gitlab-ci -d -h gitlab-ci.local.host \
  -v /opt/gitlab-ci/data:/home/gitlab_ci/data \
  -v /opt/gitlab-ci/mysql:/var/lib/mysql \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "GITLAB_CI_HOST=gitlab-ci.local.host" \
  -e "GITLAB_CI_EMAIL=gitlab@local.host" \
  -e "GITLAB_CI_SUPPORT=support@local.host" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/gitlab-ci:5.0.1
```

If you are using an external mysql database

```bash
docker run --name=gitlab-ci -d -h gitlab-ci.local.host \
  -v /opt/gitlab-ci/data:/home/gitlab_ci/data \
  -e "DB_HOST=192.168.1.100" -e "DB_NAME=gitlab_ci_production" \
  -e "DB_USER=gitlab_ci" -e "DB_PASS=password" \
  -e "GITLAB_URL=http://172.17.0.2" \
  -e "GITLAB_CI_HOST=gitlab-ci.local.host" \
  -e "GITLAB_CI_EMAIL=gitlab@local.host" \
  -e "GITLAB_CI_SUPPORT=support@local.host" \
  -e "SMTP_USER=USER@gmail.com" -e "SMTP_PASS=PASSWORD" \
  sameersbn/gitlab-ci:5.0.1
```

### Available Configuration Parameters

Below is the complete list of available options that can be used to customize your GitLab CI installation.

- **GITLAB_URL**: Url of the GitLab server to allow connections from. No defaults. Automatically configured when a GitLab server is linked using docker links feature.
- **GITLAB_CI_HOST**: The hostname of the GitLab CI server. Defaults to localhost.
- **GITLAB_CI_PORT**: The port number of the GitLab CI server. Defaults to 80 for plain http and 443 when https is enabled.
- **GITLAB_CI_EMAIL**: The email address for the GitLab CI server. Defaults to gitlab@localhost.
- **GITLAB_CI_SUPPORT**: The support email address for the GitLab CI server. Defaults to support@localhost.
- **GITLAB_CI_HTTPS**: Set to true to enable https support, disabled by default.
- **GITLAB_CI_HTTPS_ONLY**: Configure access over plain http when GITLAB_CI_HTTPS is enabled. Should be set to false when using a load balancer. Defaults to true.
- **SSL_CERTIFICATE_PATH**: Location of the ssl certificate. Defaults to /home/gitlab_ci/data/certs/gitlab.crt
- **SSL_KEY_PATH**: Location of the ssl private key. Defaults to /home/gitlab_ci/data/certs/gitlab.key
- **SSL_DHPARAM_PATH**: Location of the dhparam file. Defaults to /home/gitlab_ci/data/certs/dhparam.pem
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
- **SMTP_AUTHENTICATION**: Specify the SMTP authentication method. Defaults to :login if SMTP_USER is set.

# Maintenance

# Upgrading

To upgrade to newer GitLab CI releases, simply follow this 4 step upgrade procedure.

- **Step 1**: Stop the currently running image

```bash
docker stop gitlab-ci
```

- **Step 2**: Update the docker image.

```bash
docker pull sameersbn/gitlab-ci:5.0.1
```

- **Step 3**: Migrate the database.

```bash
docker run --name=gitlab-ci -i -t --rm [OPTIONS] \
  sameersbn/gitlab-ci:5.0.1 app:rake db:migrate
```

- **Step 4**: Start the image

```bash
docker run --name=gitlab-ci -d [OPTIONS] sameersbn/gitlab-ci:5.0.1
```

# References
  * https://www.gitlab.com/gitlab-ci/
  * https://gitlab.com/gitlab-org/gitlab-ci/blob/master/README.md
