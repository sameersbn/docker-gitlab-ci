#!/bin/bash
set -e

GITLAB_CI_HOST=${GITLAB_CI_HOST:-localhost}
GITLAB_CI_PORT=${GITLAB_CI_PORT:-}
GITLAB_CI_HTTPS=${GITLAB_CI_HTTPS:-false}
GITLAB_CI_EMAIL=${GITLAB_CI_EMAIL:-gitlab@localhost}
GITLAB_CI_SUPPORT=${GITLAB_CI_SUPPORT:-support@localhost}
GITLAB_CI_TIMEZONE=${GITLAB_CI_TIMEZONE:-UTC}
GITLAB_CI_NOTIFY_ON_BROKEN_BUILDS=${GITLAB_CI_NOTIFY_ON_BROKEN_BUILDS:-true}
GITLAB_CI_NOTIFY_PUSHER=${GITLAB_CI_NOTIFY_PUSHER:-$GITLAB_CI_NOTIFY_ADD_COMMITTER}
GITLAB_CI_NOTIFY_PUSHER=${GITLAB_CI_NOTIFY_PUSHER:-false}
GITLAB_CI_BACKUP_DIR="${GITLAB_CI_BACKUP_DIR:-$GITLAB_CI_DATA_DIR/backups}"
GITLAB_CI_BACKUPS=${GITLAB_CI_BACKUPS:-disable}
GITLAB_CI_BACKUP_TIME=${GITLAB_CI_BACKUP_TIME:-04:00}
GITLAB_CI_BACKUP_EXPIRY=${GITLAB_CI_BACKUP_EXPIRY:-}

AWS_BACKUPS=${AWS_BACKUPS:-false}
AWS_BACKUP_REGION=${AWS_BACKUP_REGION}
AWS_BACKUP_ACCESS_KEY_ID=${AWS_BACKUP_ACCESS_KEY_ID}
AWS_BACKUP_SECRET_ACCESS_KEY=${AWS_BACKUP_SECRET_ACCESS_KEY}
AWS_BACKUP_BUCKET=${AWS_BACKUP_BUCKET}

SSL_CERTIFICATE_PATH=${SSL_CERTIFICATE_PATH:-$GITLAB_CI_DATA_DIR/certs/gitlab_ci.crt}
SSL_KEY_PATH=${SSL_KEY_PATH:-$GITLAB_CI_DATA_DIR/certs/gitlab_ci.key}
SSL_DHPARAM_PATH=${SSL_DHPARAM_PATH:-$GITLAB_CI_DATA_DIR/certs/dhparam.pem}
SSL_VERIFY_CLIENT=${SSL_VERIFY_CLIENT:-off}

CA_CERTIFICATES_PATH=${CA_CERTIFICATES_PATH:-$GITLAB_CI_DATA_DIR/certs/ca.crt}

GITLAB_CI_HTTPS_HSTS_ENABLED=${GITLAB_CI_HTTPS_HSTS_ENABLED:-true}
GITLAB_CI_HTTPS_HSTS_MAX_AGE=${GITLAB_CI_HTTPS_HSTS_MAX_AGE:-31536000}

NGINX_WORKERS=${NGINX_WORKERS:-1}
NGINX_MAX_UPLOAD_SIZE=${NGINX_MAX_UPLOAD_SIZE:-20m}

REDIS_HOST=${REDIS_HOST:-}
REDIS_PORT=${REDIS_PORT:-}

UNICORN_WORKERS=${UNICORN_WORKERS:-2}
UNICORN_TIMEOUT=${UNICORN_TIMEOUT:-60}
SIDEKIQ_CONCURRENCY=${SIDEKIQ_CONCURRENCY:-25}

DB_TYPE=${DB_TYPE:-}
DB_HOST=${DB_HOST:-}
DB_PORT=${DB_PORT:-}
DB_NAME=${DB_NAME:-}
DB_USER=${DB_USER:-}
DB_PASS=${DB_PASS:-}
DB_POOL=${DB_POOL:-10}

SMTP_DOMAIN=${SMTP_DOMAIN:-www.gmail.com}
SMTP_HOST=${SMTP_HOST:-smtp.gmail.com}
SMTP_PORT=${SMTP_PORT:-587}
SMTP_USER=${SMTP_USER:-}
SMTP_PASS=${SMTP_PASS:-}
SMTP_OPENSSL_VERIFY_MODE=${SMTP_OPENSSL_VERIFY_MODE:-}
SMTP_STARTTLS=${SMTP_STARTTLS:-true}
SMTP_TLS=${SMTP_TLS:-false}
if [[ -n ${SMTP_USER} ]]; then
  SMTP_ENABLED=${SMTP_ENABLED:-true}
  SMTP_AUTHENTICATION=${SMTP_AUTHENTICATION:-login}
fi
SMTP_ENABLED=${SMTP_ENABLED:-false}

GITLAB_URL=${GITLAB_URL:-}
GITLAB_APP_ID=${GITLAB_APP_ID:-}
GITLAB_APP_SECRET=${GITLAB_APP_SECRET:-}

# use docker link feature to figure out gitlab url
[[ -z ${GITLAB_URL} && -n ${GITLAB_PORT_80_TCP_ADDR} ]] && \
  GITLAB_URL="http://${GITLAB_PORT_80_TCP_ADDR}"

GITLAB_URL=$(sed 's/\//\\\//g' <<< $GITLAB_URL)

# is a mysql or postgresql database linked?
# requires that the mysql or postgresql containers have exposed
# port 3306 and 5432 respectively.
if [[ -n ${MYSQL_PORT_3306_TCP_ADDR} ]]; then
  DB_TYPE=mysql
  DB_HOST=${DB_HOST:-${MYSQL_PORT_3306_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${MYSQL_PORT_3306_TCP_PORT}}

  # support for linked sameersbn/mysql image
  DB_USER=${DB_USER:-${MYSQL_ENV_DB_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_DB_PASS}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_DB_NAME}}

  # support for linked orchardup/mysql and centurylink/mysql image
  # also supports official mysql image
  DB_USER=${DB_USER:-${MYSQL_ENV_MYSQL_USER}}
  DB_PASS=${DB_PASS:-${MYSQL_ENV_MYSQL_PASSWORD}}
  DB_NAME=${DB_NAME:-${MYSQL_ENV_MYSQL_DATABASE}}
elif [[ -n ${POSTGRESQL_PORT_5432_TCP_ADDR} ]]; then
  DB_TYPE=postgres
  DB_HOST=${DB_HOST:-${POSTGRESQL_PORT_5432_TCP_ADDR}}
  DB_PORT=${DB_PORT:-${POSTGRESQL_PORT_5432_TCP_PORT}}

  # support for linked official postgres image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRES_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRES_PASSWORD}}
  DB_NAME=${DB_NAME:-${DB_USER}}

  # support for linked sameersbn/postgresql image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_DB_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_DB_PASS}}
  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_DB_NAME}}

  # support for linked orchardup/postgresql image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_POSTGRESQL_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_POSTGRESQL_PASS}}
  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_POSTGRESQL_DB}}

  # support for linked paintedfox/postgresql image
  DB_USER=${DB_USER:-${POSTGRESQL_ENV_USER}}
  DB_PASS=${DB_PASS:-${POSTGRESQL_ENV_PASS}}
  DB_NAME=${DB_NAME:-${POSTGRESQL_ENV_DB}}
fi

if [[ -z ${DB_HOST} ]]; then
  echo "ERROR: "
  echo "  Please configure the database connection."
  echo "  Refer http://git.io/kD0ndg for more information."
  echo "  Cannot continue without a database. Aborting..."
  exit 1
fi

# use default port number if it is still not set
case ${DB_TYPE} in
  mysql) DB_PORT=${DB_PORT:-3306} ;;
  postgres) DB_PORT=${DB_PORT:-5432} ;;
  *)
    echo "ERROR: "
    echo "  Please specify the database type in use via the DB_TYPE configuration option."
    echo "  Accepted values are \"postgres\" or \"mysql\". Aborting..."
    exit 1
    ;;
esac

# set default user and database
DB_USER=${DB_USER:-root}
DB_NAME=${DB_NAME:-gitlab_ci_production}

# is a redis container linked?
if [[ -n ${REDISIO_PORT_6379_TCP_ADDR} ]]; then
  REDIS_HOST=${REDIS_HOST:-${REDISIO_PORT_6379_TCP_ADDR}}
  REDIS_PORT=${REDIS_PORT:-${REDISIO_PORT_6379_TCP_PORT}}
fi

# fallback to default redis port
REDIS_PORT=${REDIS_PORT:-6379}

if [[ -z ${REDIS_HOST} ]]; then
  echo "ERROR: "
  echo "  Please configure the redis connection."
  echo "  Refer http://git.io/PMnRSw for more information."
  echo "  Cannot continue without a redis connection. Aborting..."
  exit 1
fi

case ${GITLAB_CI_HTTPS} in
  true)
    GITLAB_CI_PORT=${GITLAB_CI_PORT:-443}
    NGINX_X_FORWARDED_PROTO=${NGINX_X_FORWARDED_PROTO:-https}
    ;;
  *)
    GITLAB_CI_PORT=${GITLAB_CI_PORT:-80}
    NGINX_X_FORWARDED_PROTO=${NGINX_X_FORWARDED_PROTO:-\$scheme}
    ;;
esac

case ${GITLAB_CI_BACKUPS} in
  daily|weekly|monthly) GITLAB_CI_BACKUP_EXPIRY=${GITLAB_CI_BACKUP_EXPIRY:-604800} ;;
  disable|*) GITLAB_CI_BACKUP_EXPIRY=${GITLAB_CI_BACKUP_EXPIRY:-0} ;;
esac

# populate ${GITLAB_CI_LOG_DIR}
mkdir -m 0755 -p ${GITLAB_CI_LOG_DIR}/supervisor  && chown -R root:root ${GITLAB_CI_LOG_DIR}/supervisor
mkdir -m 0755 -p ${GITLAB_CI_LOG_DIR}/nginx       && chown -R ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_LOG_DIR}/nginx
mkdir -m 0755 -p ${GITLAB_CI_LOG_DIR}/gitlab-ci   && chown -R ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_LOG_DIR}/gitlab-ci

cd ${GITLAB_CI_INSTALL_DIR}

# copy configuration templates
case ${GITLAB_CI_HTTPS} in
  true)
    if [[ -f ${SSL_CERTIFICATE_PATH} && -f ${SSL_KEY_PATH} && -f ${SSL_DHPARAM_PATH} ]]; then
      cp ${SETUP_DIR}/config/nginx/gitlab_ci-ssl /etc/nginx/sites-enabled/gitlab_ci
    else
      echo "SSL keys and certificates were not found."
      echo "Assuming that the container is running behind a HTTPS enabled load balancer."
      cp ${SETUP_DIR}/config/nginx/gitlab_ci /etc/nginx/sites-enabled/gitlab_ci
    fi
    ;;
  *) cp ${SETUP_DIR}/config/nginx/gitlab_ci /etc/nginx/sites-enabled/gitlab_ci ;;
esac
sudo -HEu ${GITLAB_CI_USER} cp ${SETUP_DIR}/config/gitlab-ci/application.yml config/application.yml
sudo -HEu ${GITLAB_CI_USER} cp ${SETUP_DIR}/config/gitlab-ci/resque.yml config/resque.yml
sudo -HEu ${GITLAB_CI_USER} cp ${SETUP_DIR}/config/gitlab-ci/database.yml config/database.yml
sudo -HEu ${GITLAB_CI_USER} cp ${SETUP_DIR}/config/gitlab-ci/unicorn.rb config/unicorn.rb
[[ ${SMTP_ENABLED} == true ]] && \
sudo -HEu ${GITLAB_CI_USER} cp ${SETUP_DIR}/config/gitlab-ci/smtp_settings.rb config/initializers/smtp_settings.rb

# override default configuration templates with user templates
case ${GITLAB_CI_HTTPS} in
  true)
    if [[ -f ${SSL_CERTIFICATE_PATH} && -f ${SSL_KEY_PATH} && -f ${SSL_DHPARAM_PATH} ]]; then
      [[ -f ${GITLAB_CI_DATA_DIR}/config/nginx/gitlab_ci-ssl ]] && cp ${GITLAB_CI_DATA_DIR}/config/nginx/gitlab_ci-ssl /etc/nginx/sites-enabled/gitlab_ci
    else
      [[ -f ${GITLAB_CI_DATA_DIR}/nginx/gitlab_ci ]] && cp ${GITLAB_CI_DATA_DIR}/nginx/gitlab_ci /etc/nginx/sites-enabled/gitlab_ci
    fi
    ;;
  *) [[ -f ${GITLAB_CI_DATA_DIR}/nginx/gitlab_ci ]] && cp ${GITLAB_CI_DATA_DIR}/nginx/gitlab_ci /etc/nginx/sites-enabled/gitlab_ci ;;
esac
[[ -f ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/application.yml ]]  && sudo -HEu ${GITLAB_CI_USER} cp ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/application.yml  config/application.yml
[[ -f ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/resque.yml ]]       && sudo -HEu ${GITLAB_CI_USER} cp ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/resque.yml       config/resque.yml
[[ -f ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/database.yml ]]     && sudo -HEu ${GITLAB_CI_USER} cp ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/database.yml     config/database.yml
[[ -f ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/unicorn.rb ]]       && sudo -HEu ${GITLAB_CI_USER} cp ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/unicorn.rb       config/unicorn.rb
[[ ${SMTP_ENABLED} == true ]] && \
[[ -f ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/smtp_settings.rb ]] && sudo -HEu ${GITLAB_CI_USER} cp ${GITLAB_CI_DATA_DIR}/config/gitlab-ci/smtp_settings.rb config/initializers/smtp_settings.rb

if [[ -f ${SSL_CERTIFICATE_PATH} || -f ${CA_CERTIFICATES_PATH} ]]; then
  echo "Updating CA certificates..."
  [[ -f ${SSL_CERTIFICATE_PATH} ]] && \
    cp "${SSL_CERTIFICATE_PATH}" /usr/local/share/ca-certificates/gitlab_ci.crt
  [[ -f ${CA_CERTIFICATES_PATH} ]] && \
    cp "${CA_CERTIFICATES_PATH}" /usr/local/share/ca-certificates/ca.crt
  update-ca-certificates --fresh >/dev/null
fi

# configure nginx
sed 's,{{GITLAB_CI_INSTALL_DIR}},'"${GITLAB_CI_INSTALL_DIR}"',g' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's,{{GITLAB_CI_LOG_DIR}},'"${GITLAB_CI_LOG_DIR}"',g' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's/{{YOUR_SERVER_FQDN}}/'"${GITLAB_CI_HOST}"'/g' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's/{{GITLAB_CI_PORT}}/'"${GITLAB_CI_PORT}"'/' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's,{{SSL_CERTIFICATE_PATH}},'"${SSL_CERTIFICATE_PATH}"',' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's,{{SSL_KEY_PATH}},'"${SSL_KEY_PATH}"',' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's,{{SSL_DHPARAM_PATH}},'"${SSL_DHPARAM_PATH}"',' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's,{{SSL_VERIFY_CLIENT}},'"${SSL_VERIFY_CLIENT}"',' -i /etc/nginx/sites-enabled/gitlab_ci
if [[ -f ${CA_CERTIFICATES_PATH} ]]; then
  sed 's,{{CA_CERTIFICATES_PATH}},'"${CA_CERTIFICATES_PATH}"',' -i /etc/nginx/sites-enabled/gitlab_ci
else
  sed '/{{CA_CERTIFICATES_PATH}}/d' -i /etc/nginx/sites-enabled/gitlab_ci
fi

sed 's/worker_processes .*/worker_processes '"${NGINX_WORKERS}"';/' -i /etc/nginx/nginx.conf
sed 's/{{NGINX_MAX_UPLOAD_SIZE}}/'"${NGINX_MAX_UPLOAD_SIZE}"'/g' -i /etc/nginx/sites-enabled/gitlab_ci
sed 's,{{NGINX_X_FORWARDED_PROTO}},'"${NGINX_X_FORWARDED_PROTO}"',g' -i /etc/nginx/sites-enabled/gitlab_ci

if [[ ${GITLAB_CI_HTTPS_HSTS_ENABLED} == true ]]; then
  sed 's/{{GITLAB_CI_HTTPS_HSTS_MAX_AGE}}/'"${GITLAB_CI_HTTPS_HSTS_MAX_AGE}"'/' -i /etc/nginx/sites-enabled/gitlab_ci
else
  sed '/{{GITLAB_CI_HTTPS_HSTS_MAX_AGE}}/d' -i /etc/nginx/sites-enabled/gitlab_ci
fi

# configure relative_url_root
if [[ -n ${GITLAB_CI_RELATIVE_URL_ROOT} ]]; then
  sed 's,{{GITLAB_CI_RELATIVE_URL_ROOT}},'"${GITLAB_CI_RELATIVE_URL_ROOT}"',' -i /etc/nginx/sites-enabled/gitlab_ci
  sed 's,# alias '"${GITLAB_CI_INSTALL_DIR}"'/public,alias '"${GITLAB_CI_INSTALL_DIR}"'/public,' -i /etc/nginx/sites-enabled/gitlab_ci
  sudo -HEu ${GITLAB_CI_USER} sed 's,{{GITLAB_CI_RELATIVE_URL_ROOT}},'"${GITLAB_CI_RELATIVE_URL_ROOT}"',' -i config/unicorn.rb
else
  sed 's,{{GITLAB_CI_RELATIVE_URL_ROOT}},/,' -i /etc/nginx/sites-enabled/gitlab_ci
  sudo -HEu ${GITLAB_CI_USER} sed '/{{GITLAB_CI_RELATIVE_URL_ROOT}}/d' -i config/unicorn.rb
fi

# disable ipv6 support
if [[ ! -f /proc/net/if_inet6 ]]; then
  sed -e '/listen \[::\]:80/ s/^#*/#/' -i /etc/nginx/sites-enabled/gitlab_ci
  sed -e '/listen \[::\]:443/ s/^#*/#/' -i /etc/nginx/sites-enabled/gitlab_ci
fi

# configure server url
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_URL}}/'"${GITLAB_URL}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_APP_ID}}/'"${GITLAB_APP_ID}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_APP_SECRET}}/'"${GITLAB_APP_SECRET}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_HOST}}/'"${GITLAB_CI_HOST}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_PORT}}/'"${GITLAB_CI_PORT}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_HTTPS}}/'"${GITLAB_CI_HTTPS}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_EMAIL}}/'"${GITLAB_CI_EMAIL}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_SUPPORT}}/'"${GITLAB_CI_SUPPORT}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_NOTIFY_ON_BROKEN_BUILDS}}/'"${GITLAB_CI_NOTIFY_ON_BROKEN_BUILDS}"'/' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{GITLAB_CI_NOTIFY_PUSHER}}/'"${GITLAB_CI_NOTIFY_PUSHER}"'/' -i config/application.yml

# configure backups
sudo -HEu ${GITLAB_CI_USER} sed 's,{{GITLAB_CI_BACKUP_DIR}},'"${GITLAB_CI_BACKUP_DIR}"',g' -i config/application.yml
sudo -HEu ${GITLAB_CI_USER} sed 's,{{GITLAB_CI_BACKUP_EXPIRY}},'"${GITLAB_CI_BACKUP_EXPIRY}"',g' -i config/application.yml

# apply aws s3 backup configuration
case ${AWS_BACKUPS} in
  true)
    if [[ -z ${AWS_BACKUP_REGION} || -z ${AWS_BACKUP_ACCESS_KEY_ID} || -z ${AWS_BACKUP_SECRET_ACCESS_KEY} || -z ${AWS_BACKUP_BUCKET} ]]; then
      printf "\nMissing AWS options. Aborting...\n"
      exit 1
    fi
    sudo -HEu ${GITLAB_CI_USER} sed 's/{{AWS_BACKUP_REGION}}/'"${AWS_BACKUP_REGION}"'/' -i config/application.yml
    sudo -HEu ${GITLAB_CI_USER} sed 's/{{AWS_BACKUP_ACCESS_KEY_ID}}/'"${AWS_BACKUP_ACCESS_KEY_ID}"'/' -i config/application.yml
    sudo -HEu ${GITLAB_CI_USER} sed 's,{{AWS_BACKUP_SECRET_ACCESS_KEY}},'"${AWS_BACKUP_SECRET_ACCESS_KEY}"',' -i config/application.yml
    sudo -HEu ${GITLAB_CI_USER} sed 's/{{AWS_BACKUP_BUCKET}}/'"${AWS_BACKUP_BUCKET}"'/' -i config/application.yml
    ;;
  *)
    # remove backup configuration lines
    sudo -HEu ${GITLAB_CI_USER} sed /upload:/,/remote_directory:/d -i config/application.yml
    ;;
esac

# configure timezone
sudo -HEu ${GITLAB_CI_USER} sed "s/# config.time_zone.*/config.time_zone = '${GITLAB_CI_TIMEZONE}'/" -i config/application.rb

# configure database
if [[ ${DB_TYPE} == postgres ]]; then
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_ADAPTER}}/postgresql/' -i config/database.yml
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_ENCODING}}/unicode/' -i config/database.yml
  sudo -HEu ${GITLAB_CI_USER} sed 's/reconnect: false/#reconnect: false/' -i config/database.yml
elif [[ ${DB_TYPE} == mysql ]]; then
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_ADAPTER}}/mysql2/' -i config/database.yml
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_ENCODING}}/utf8/' -i config/database.yml
  sudo -HEu ${GITLAB_CI_USER} sed 's/#reconnect: false/reconnect: false/' -i config/database.yml
else
  echo "Invalid database type: '$DB_TYPE'. Supported choices: [mysql, postgres]."
fi

sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_HOST}}/'"${DB_HOST}"'/' -i config/database.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_PORT}}/'"${DB_PORT}"'/' -i config/database.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_NAME}}/'"${DB_NAME}"'/' -i config/database.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_USER}}/'"${DB_USER}"'/' -i config/database.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_PASS}}/'"${DB_PASS}"'/' -i config/database.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{DB_POOL}}/'"${DB_POOL}"'/' -i config/database.yml

# configure sidekiq concurrency
sed 's/{{SIDEKIQ_CONCURRENCY}}/'"${SIDEKIQ_CONCURRENCY}"'/' -i /etc/supervisor/conf.d/sidekiq.conf

# configure redis
sudo -HEu ${GITLAB_CI_USER} sed 's/{{REDIS_HOST}}/'"${REDIS_HOST}"'/g' -i config/resque.yml
sudo -HEu ${GITLAB_CI_USER} sed 's/{{REDIS_PORT}}/'"${REDIS_PORT}"'/g' -i config/resque.yml

# configure unicorn
sudo -HEu ${GITLAB_CI_USER} sed 's,{{GITLAB_CI_INSTALL_DIR}},'"${GITLAB_CI_INSTALL_DIR}"',g' -i config/unicorn.rb
sudo -HEu ${GITLAB_CI_USER} sed 's/{{UNICORN_WORKERS}}/'"${UNICORN_WORKERS}"'/' -i config/unicorn.rb
sudo -HEu ${GITLAB_CI_USER} sed 's/{{UNICORN_TIMEOUT}}/'"${UNICORN_TIMEOUT}"'/' -i config/unicorn.rb

# configure mail delivery
if [[ ${SMTP_ENABLED} == true ]]; then
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_HOST}}/'"${SMTP_HOST}"'/' -i config/initializers/smtp_settings.rb
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_PORT}}/'"${SMTP_PORT}"'/' -i config/initializers/smtp_settings.rb

  case ${SMTP_USER} in
    "") sudo -HEu ${GITLAB_CI_USER} sed '/{{SMTP_USER}}/d' -i config/initializers/smtp_settings.rb ;;
    *) sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_USER}}/'"${SMTP_USER}"'/' -i config/initializers/smtp_settings.rb ;;
  esac

  case ${SMTP_PASS} in
    "") sudo -HEu ${GITLAB_CI_USER} sed '/{{SMTP_PASS}}/d' -i config/initializers/smtp_settings.rb ;;
    *) sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_PASS}}/'"${SMTP_PASS}"'/' -i config/initializers/smtp_settings.rb ;;
  esac

  sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_DOMAIN}}/'"${SMTP_DOMAIN}"'/' -i config/initializers/smtp_settings.rb
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_STARTTLS}}/'"${SMTP_STARTTLS}"'/' -i config/initializers/smtp_settings.rb
  sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_TLS}}/'"${SMTP_TLS}"'/' -i config/initializers/smtp_settings.rb

  if [[ -n ${SMTP_OPENSSL_VERIFY_MODE} ]]; then
    sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_OPENSSL_VERIFY_MODE}}/'"${SMTP_OPENSSL_VERIFY_MODE}"'/' -i config/initializers/smtp_settings.rb
  else
    sudo -HEu ${GITLAB_CI_USER} sed '/{{SMTP_OPENSSL_VERIFY_MODE}}/d' -i config/initializers/smtp_settings.rb
  fi

  case ${SMTP_AUTHENTICATION} in
    "") sudo -HEu ${GITLAB_CI_USER} sed '/{{SMTP_AUTHENTICATION}}/d' -i config/initializers/smtp_settings.rb ;;
    *) sudo -HEu ${GITLAB_CI_USER} sed 's/{{SMTP_AUTHENTICATION}}/'"${SMTP_AUTHENTICATION}"'/' -i config/initializers/smtp_settings.rb ;;
  esac
fi

# take ownership of ${GITLAB_CI_DATA_DIR}
chown ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_DATA_DIR}

# create the backups directory
mkdir -p ${GITLAB_CI_BACKUP_DIR}
chown ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_BACKUP_DIR}

appInit () {
  # due to the nature of docker and its use cases, we allow some time
  # for the database server to come online.
  case ${DB_TYPE} in
    mysql)
      prog="mysqladmin -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} status"
      ;;
    postgres)
      prog=$(find /usr/lib/postgresql/ -name pg_isready)
      prog="${prog} -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -t 1"
      ;;
  esac
  timeout=60
  echo -n "Waiting for database server to accept connections"
  while ! ${prog} >/dev/null 2>&1
  do
    timeout=$(expr $timeout - 1)
    if [[ $timeout -eq 0 ]]; then
      echo -e "\nCould not connect to database server. Aborting..."
      exit 1
    fi
    echo -n "."
    sleep 1
  done
  echo

  # run the `db:setup` rake task if required
  case ${DB_TYPE} in
    mysql)
      QUERY="SELECT count(*) FROM information_schema.tables WHERE table_schema = '${DB_NAME}';"
      COUNT=$(mysql -h ${DB_HOST} -P ${DB_PORT} -u ${DB_USER} ${DB_PASS:+-p$DB_PASS} -ss -e "${QUERY}")
      ;;
    postgres)
      QUERY="SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
      COUNT=$(PGPASSWORD="${DB_PASS}" psql -h ${DB_HOST} -p ${DB_PORT} -U ${DB_USER} -d ${DB_NAME} -Atw -c "${QUERY}")
      ;;
  esac
  if [[ -z ${COUNT} || ${COUNT} -eq 0 ]]; then
    echo "Setting up GitLab CI for firstrun. Please be patient, this could take a while..."
    sudo -HEu ${GITLAB_CI_USER} bundle exec rake db:setup RAILS_ENV=production >/dev/null
  fi

  # migrate database if the gitlab-ci version has changed.
  CURRENT_VERSION=
  [[ -f ${GITLAB_CI_DATA_DIR}/VERSION ]] && CURRENT_VERSION=$(cat ${GITLAB_CI_DATA_DIR}/VERSION)
  if [[ ${GITLAB_CI_VERSION} != ${CURRENT_VERSION} ]]; then
    echo "Migrating database..."
    sudo -HEu ${GITLAB_CI_USER} bundle exec rake db:migrate RAILS_ENV=production >/dev/null
    sudo -HEu ${GITLAB_CI_USER} echo "${GITLAB_CI_VERSION}" > ${GITLAB_CI_DATA_DIR}/VERSION
  fi

  # setup cron job for automatic backups
  case ${GITLAB_CI_BACKUPS} in
    daily|weekly|monthly)
      read hour min <<< ${GITLAB_CI_BACKUP_TIME//[:]/ }
      crontab -u ${GITLAB_CI_USER} -l > /tmp/cron.${GITLAB_CI_USER}
      case ${GITLAB_CI_BACKUPS} in
        daily)
          sudo -HEu ${GITLAB_CI_USER} cat >> /tmp/cron.${GITLAB_CI_USER} <<EOF
# Automatic Backups: daily
$min $hour * * * /bin/bash -l -c 'cd ${GITLAB_CI_INSTALL_DIR} && bundle exec rake backup:create RAILS_ENV=production'
EOF
          ;;
        weekly)
          sudo -HEu ${GITLAB_CI_USER} cat >> /tmp/cron.${GITLAB_CI_USER} <<EOF
# Automatic Backups: weekly
$min $hour * * 0 /bin/bash -l -c 'cd ${GITLAB_CI_INSTALL_DIR} && bundle exec rake backup:create RAILS_ENV=production'
EOF
          ;;
        monthly)
          sudo -HEu ${GITLAB_CI_USER} cat >> /tmp/cron.${GITLAB_CI_USER} <<EOF
# Automatic Backups: monthly
$min $hour 01 * * /bin/bash -l -c 'cd ${GITLAB_CI_INSTALL_DIR} && bundle exec rake backup:create RAILS_ENV=production'
EOF
          ;;
    esac
    crontab -u ${GITLAB_CI_USER} /tmp/cron.${GITLAB_CI_USER} && rm -rf /tmp/cron.${GITLAB_CI_USER}
    ;;
  esac

  # remove stale unicorn and sidekiq pid's if they exist.
  rm -rf tmp/pids/unicorn.pid
  rm -rf tmp/pids/sidekiq.pid

  # remove state unicorn socket if it exists
  rm -rf tmp/sockets/gitlab_ci.socket
}

appStart () {
  appInit
  # start supervisord
  exec /usr/bin/supervisord -n -c /etc/supervisor/supervisord.conf
}

appRake () {
  if [[ -z ${1} ]]; then
    echo "Please specify the rake task to execute."
    return 1
  fi

  echo "Running gitlab ci rake task..."

  if [[ ${1} == backup:restore ]]; then
    # check if the BACKUP argument is specified
    for a in $@
    do
      if [[ $a == BACKUP=* ]]; then
        timestamp=${a:7}
        break
      fi
    done

    if [[ -z ${timestamp} ]]; then
      # user needs to select the backup to restore
      nBackups=$(ls ${GITLAB_CI_BACKUP_DIR}/*_gitlab_ci_backup.tar.gz | wc -l)
      if [[ $nBackups -eq 0 ]]; then
        echo "No backup present. Cannot continue restore process.".
        return 1
      fi

      for b in `ls ${GITLAB_CI_BACKUP_DIR} | sort -r`
      do
        echo " ├ $b"
      done
      read -p "Select a backup to restore: " file

      if [[ ! -f ${GITLAB_CI_BACKUP_DIR}/${file} ]]; then
        echo "Specified backup does not exist. Aborting..."
        return 1
      fi
      timestamp=$(echo $file | cut -d'_' -f1)
    fi
    sudo -HEu ${GITLAB_CI_USER} bundle exec rake backup:restore BACKUP=$timestamp RAILS_ENV=production
  else
    sudo -HEu ${GITLAB_CI_USER} bundle exec rake $@ RAILS_ENV=production
  fi
}

appHelp () {
  echo "Available options:"
  echo " app:start          - Starts the gitlab-ci server (default)"
  echo " app:init           - Initialize the gitlab-ci server (e.g. create databases, compile assets), but don't start it."
  echo " app:rake <task>    - Execute a rake task."
  echo " app:help           - Displays the help"
  echo " [command]          - Execute the specified linux command eg. bash."
}

case ${1} in
  app:start)
    appStart
    ;;
  app:init)
    appInit
    ;;
  app:rake)
    shift 1
    appRake $@
    ;;
  app:help)
    appHelp
    ;;
  *)
    if [[ -x ${1} ]]; then
      ${1}
    else
      prog=$(which ${1})
      if [[ -n ${prog} ]] ; then
        shift 1
        $prog $@
      else
        appHelp
      fi
    fi
    ;;
esac

exit 0
