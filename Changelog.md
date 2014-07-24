# Changelog

**latest**
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
