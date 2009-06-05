# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_sign_in_session',
  :secret      => '2c38fdb9135b70b6a015ef4793a8d7f87080b0685979063d68cbe7e3b1628d27e1d2be433c610ff845d33e4c4c9db4180e53682af8a172474332b4b5add382f8'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
