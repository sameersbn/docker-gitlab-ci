#!/bin/bash
set -e

GEM_CACHE_DIR="${SETUP_DIR}/cache"

# rebuild apt cache
apt-get update

# install build dependencies for gem installation
DEBIAN_FRONTEND=noninteractive apt-get install -y gcc g++ make patch paxctl libc6-dev ruby2.1-dev \
  libmysqlclient-dev libpq-dev zlib1g-dev libyaml-dev libssl-dev \
  libgdbm-dev libreadline-dev libncurses5-dev libffi-dev \
  libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev

# https://en.wikibooks.org/wiki/Grsecurity/Application-specific_Settings#Node.js
paxctl -Cm `which nodejs`

# add gitlab_ci user
adduser --disabled-login --gecos 'GitLab CI' ${GITLAB_CI_USER}

# set PATH (fixes cron job PATH issues)
cat >> ${GITLAB_CI_HOME}/.profile <<EOF
PATH=/usr/local/sbin:/usr/local/bin:\$PATH
EOF

# create the data store
sudo -HEu ${GITLAB_CI_USER} mkdir -p ${GITLAB_CI_DATA_DIR}

# shallow clone gitlab-ci
echo "Cloning gitlab-ci v.${GITLAB_CI_VERSION}..."
sudo -HEu ${GITLAB_CI_USER} git clone -q -b v${GITLAB_CI_VERSION} --depth 1 \
  https://github.com/gitlabhq/gitlab-ci.git ${GITLAB_CI_INSTALL_DIR}

cd ${GITLAB_CI_INSTALL_DIR}

# copy default configurations
cp lib/support/nginx/gitlab_ci /etc/nginx/sites-available/gitlab_ci
sudo -HEu ${GITLAB_CI_USER} cp config/application.yml.example config/application.yml
sudo -HEu ${GITLAB_CI_USER} cp config/secrets.yml.example config/secrets.yml
sudo -HEu ${GITLAB_CI_USER} cp config/resque.yml.example config/resque.yml
sudo -HEu ${GITLAB_CI_USER} cp config/database.yml.mysql config/database.yml
sudo -HEu ${GITLAB_CI_USER} cp config/unicorn.rb.example config/unicorn.rb

# symlink log -> ${GITLAB_CI_LOG_DIR}/gitlab-ci
rm -rf log
ln -sf ${GITLAB_CI_LOG_DIR}/gitlab-ci log

# create required tmp directories
sudo -HEu ${GITLAB_CI_USER} mkdir -p tmp/pids/ tmp/sockets/
chmod -R u+rwX tmp

# install gems required by gitlab-ci, use cache if available
if [[ -d ${GEM_CACHE_DIR} ]]; then
  mv ${GEM_CACHE_DIR} vendor/
  chown -R ${GITLAB_CI_USER}:${GITLAB_CI_USER} vendor/cache
fi

sudo -HEu ${GITLAB_CI_USER} bundle install -j$(nproc) --deployment --without development test

# install cronjob
bundle exec whenever -w -u ${GITLAB_CI_USER}

# make sure everything in ${GITLAB_CI_HOME} is owned by the ${GITLAB_CI_USER} user
chown -R ${GITLAB_CI_USER}:${GITLAB_CI_USER} ${GITLAB_CI_HOME}/

# install gitlab bootscript
cp lib/support/init.d/gitlab_ci /etc/init.d/gitlab_ci

# disable default nginx configuration and enable gitlab's nginx configuration
rm -f /etc/nginx/sites-enabled/default

# create the /var/run/sshd directory (required for sshd to start)
mkdir -p /var/run/sshd

# move supervisord.log file to ${GITLAB_CI_LOG_DIR}/supervisor/
sed 's|^logfile=.*|logfile='"${GITLAB_CI_LOG_DIR}"'/supervisor/supervisord.log ;|' -i /etc/supervisor/supervisord.conf

# move nginx logs to ${GITLAB_CI_LOG_DIR}/nginx
sed 's|access_log /var/log/nginx/access.log;|access_log '"${GITLAB_CI_LOG_DIR}"'/nginx/access.log;|' -i /etc/nginx/nginx.conf
sed 's|error_log /var/log/nginx/error.log;|error_log '"${GITLAB_CI_LOG_DIR}"'/nginx/error.log;|' -i /etc/nginx/nginx.conf

# configure supervisord log rotation
cat > /etc/logrotate.d/supervisord <<EOF
${GITLAB_CI_LOG_DIR}/supervisor/*.log {
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  copytruncate
}
EOF

# configure gitlab-ci log rotation
cat > /etc/logrotate.d/gitlab-ci <<EOF
${GITLAB_CI_LOG_DIR}/gitlab-ci/*.log {
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  copytruncate
}
EOF

# configure gitlab-ci vhost log rotation
cat > /etc/logrotate.d/gitlab-ci-vhost <<EOF
${GITLAB_CI_LOG_DIR}/nginx/*.log {
  weekly
  missingok
  rotate 52
  compress
  delaycompress
  notifempty
  copytruncate
}
EOF

# configure supervisord to start unicorn
cat > /etc/supervisor/conf.d/unicorn.conf <<EOF
[program:unicorn]
priority=10
directory=${GITLAB_CI_INSTALL_DIR}
environment=HOME=${GITLAB_CI_HOME}
command=bundle exec unicorn_rails -c ${GITLAB_CI_INSTALL_DIR}/config/unicorn.rb -E ${RAILS_ENV}
user=${GITLAB_CI_USER}
autostart=true
autorestart=true
stopsignal=QUIT
stdout_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# configure supervisord to start sidekiq
cat > /etc/supervisor/conf.d/sidekiq.conf <<EOF
[program:sidekiq]
priority=10
directory=${GITLAB_CI_INSTALL_DIR}
environment=HOME=${GITLAB_CI_HOME}
command=bundle exec sidekiq -c {{SIDEKIQ_CONCURRENCY}}
  -q runner
  -q common
  -q default
  -e ${RAILS_ENV}
  -P ${GITLAB_CI_INSTALL_DIR}/tmp/pids/sidekiq.pid
  -L ${GITLAB_CI_INSTALL_DIR}/log/sidekiq.log
user=${GITLAB_CI_USER}
autostart=true
autorestart=true
stdout_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# configure supervisord to start nginx
cat > /etc/supervisor/conf.d/nginx.conf <<EOF
[program:nginx]
priority=20
directory=/tmp
command=/usr/sbin/nginx -g "daemon off;"
user=root
autostart=true
autorestart=true
stdout_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# configure supervisord to start crond
cat > /etc/supervisor/conf.d/cron.conf <<EOF
[program:cron]
priority=20
directory=/tmp
command=/usr/sbin/cron -f
user=root
autostart=true
autorestart=true
stdout_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
stderr_logfile=${GITLAB_CI_LOG_DIR}/supervisor/%(program_name)s.log
EOF

# purge build dependencies
apt-get purge -y --auto-remove gcc g++ make patch paxctl libc6-dev ruby-dev \
  libmysqlclient-dev libpq-dev zlib1g-dev libyaml-dev libssl-dev \
  libgdbm-dev libreadline-dev libncurses5-dev libffi-dev \
  libxml2-dev libxslt-dev libcurl4-openssl-dev libicu-dev

# cleanup
rm -rf /var/lib/apt/lists/*
