# To enable smtp email delivery for your GitLab CI instance do next:
# 1. Rename this file to smtp_settings.rb
# 2. Edit settings inside this file
# 3. Restart GitLab CI instance
#
if Rails.env.production?
  ActionMailer::Base.delivery_method = :smtp

  ActionMailer::Base.smtp_settings = {
    address: "{{SMTP_HOST}}",
    port: {{SMTP_PORT}},
    user_name: "{{SMTP_USER}}",
    password: "{{SMTP_PASS}}",
    domain: "{{SMTP_DOMAIN}}",
    authentication: "{{SMTP_AUTHENTICATION}}",
    openssl_verify_mode: "{{SMTP_OPENSSL_VERIFY_MODE}}",
    enable_starttls_auto: {{SMTP_STARTTLS}}
  }
end
