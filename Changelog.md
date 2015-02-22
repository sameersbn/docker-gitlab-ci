# Changelog

**7.8.0**
- update postgresql client to the latest version
- gitlab-ci: upgrade to v.7.8.0

**5.4.2**
- gitlab-ci: upgrade to v.5.4.2

**5.4.1**
- gitlab-ci: upgrade to v.5.4.1

**5.4.0**
- feature: gitlab-ci logs volume
- added `SSL_VERIFY_CLIENT` configuration option
- added `SIDEKIQ_CONCURRENCY` configuration option
- gitlab-ci: upgrade to v.5.4.0
- added `GITLAB_APP_ID` and `GITLAB_APP_SECRET` configuration options

**5.3.0**
- upgrade to gitlab-ci 5.3.0

**5.2.1**
- upgrade to gitlab-ci 5.2.1

**5.2.0**
- upgrade to gitlab-ci 5.2.0

**5.1.0-1**
- added `NGINX_WORKERS` configuration option

**5.1.0**
- gitlab-ci: upgrade to v.5.1.0
- added SMTP_OPENSSL_VERIFY_MODE configuration option
- autolaunch all daemons via supervisord
- start unicorn and sidekiq using supervisord
- automatically run the `db:setup` rake task for new installs
- removed internal mysql server
- update to sameersbn/ubuntu:14.04.20141001 base image
- added support for fetching `DB_NAME`, `DB_USER` and `DB_PASS` from the postgresql linkage
- added support for fetching `DB_NAME`, `DB_USER` and `DB_PASS` from the mysql linkage
- removed internal redis server
- added GITLAB_CI_HTTPS_HSTS_ENABLED configuration option (advanced config)
- added GITLAB_CI_HTTPS_HSTS_MAX_AGE configuration option (advanced config)
- shutdown the container gracefully
- purge development packages after install. shaves off ~150MB from the image.

**5.0.1-1**
- added GITLAB_CI_NOTIFY_ADD_COMMITTER configuration option
- added GITLAB_CI_NOTIFY_ON_BROKEN_BUILDS configuration option.
- added GITLAB_CI_RELATIVE_URL_ROOT configuration option.
- update to sameersbn/ubuntu:14.04.20140628 image
- added new SMTP_ENABLED configuration option.
- update to the sameersbn/ubuntu:12.04.20140818 baseimage
- added NGINX_MAX_UPLOAD_SIZE configuration option.
- update to the sameersbn/ubuntu:12.04.20140812 baseimage
- set SMTP_AUTHENTICATION to 'login' by default.
- shallow clone gitlab-ci
- automatically migrate the database when the gitlab-ci version changes
- enabled spdy support
- upgrade to nginx-1.6.x series from the nginx/stable ppa
- update to sameersbn/ubuntu:12.04.20140628 image
- removed sshd start, use nsenter instead

**5.0.1**
- upgrade to gitlab-ci 5.0.1

**5.0.0**
- upgrade to gitlab-ci 5.0.0
- upgrade sameersbn/ubuntu:14.04.20140508 base image
- added CA_CERTIFICATES_PATH configuration option to specify trusted root certificates.
- added SSL_DHPARAM_PATH configuration option to specify path of dhparam.pem file.
- added SSL_KEY_PATH configuration option to specify path of ssl private key
- added SSL_CERTIFICATE_PATH configuration option to specify path of ssl certificate
- added GITLAB_CI_HTTPS_ONLY configuration option
- added support for linking with redis container.
- use sameersbn/ubuntu as the base docker image
- support linking to mysql and postgresql containers
- added SMTP_AUTHENTICATION config option, defaults to :login
- install ruby2.0 from ppa

**4.3.0**
- added README
- initial creation, adapted from https://github.com/sameersbn/docker-gitlab
