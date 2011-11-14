# Be sure to restart your server when you modify this file.

#ActionController::Base.session = {
#  :key         => '_crossval_session',
#  :secret      => 'b763ae0d72229868e61e4eabdacdae5923e751edd098992f806bd175d217770507e1bcab12f482a6e7348ad5e7e736d90c45251d9399582ca5dc2e729f6d6c04'
#}

Crossval::Application.config.session_store :cookie_store, key: '_crossval_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Crossval::Application.config.session_store :active_record_store
