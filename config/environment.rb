# Be sure to restart your server when you modify this file

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Specify gems that this application depends on and have them installed with rake gems:install
  # config.gem "bj"
  # config.gem "hpricot", :version => '0.6', :source => "http://code.whytheluckystiff.net"
  # config.gem "sqlite3-ruby", :lib => "sqlite3"
  # config.gem "aws-s3", :lib => "aws/s3"
  
  # DataMapper support
  config.gem "addressable", 
    :lib => "addressable/uri"  
  config.gem "data_objects"
  config.gem "do_sqlite3"
  config.gem "dm-core"
  
  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.

  # DataMapper support
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer  

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'
  
  # Old school migration numbering
  config.active_record.timestamped_migrations = false

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
end

Mime::Type.register "application/pdf", :pdf

# Note: Include an initializer for these host-specific settings.
# User.ldap_host                     ldap server host ip address or dns name
# User.ldap_port                     ldap server port
# User.ldap_base                     dn of container for all users
# User.ldap_admin_dn                 ldap manager dn
# User.ldap_admin_pw                 ldap manager password
# LdapAuthenticator.ldapadd_path     path to ldapadd executable
# LdapAuthenticator.ldapmodify_path  path to ldapmodify executable
# Employee.ldap_container            dn of container for Open Directory staff logins
# Student.ldap_student_container     dn of container for Open Directory student logins
# Student.ldap_guardian_container    dn of container for PowerSchool guardian logins
# ClearanceMailer.host               base url for links in account email notifications
# ClearanceMailer.from               from address of account email notifications

require 'clearance/extensions/errors'
require 'clearance/extensions/rescue'
require 'misc_utils'
require 'ldap_authenticator'
require 'unquoted_csv'
