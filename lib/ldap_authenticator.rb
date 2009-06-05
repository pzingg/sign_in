require 'net/ldap'

class LdapAuthenticator
  cattr_accessor :ldapmodify_path, :ldapadd_path
  
  def initialize(host, port, admin_dn, admin_pw)
    @ldap = Net::LDAP.new(:host => host, :port => port)
    @admin_dn = admin_dn
    @admin_pw = admin_pw
  end
  
  def authenticate(base, filter, passwd)
    authenticated_entry = nil
    begin
      @ldap.auth(@admin_dn, @admin_pw)
      count = 0
      
      # We could use @ldap.bind_as here, but that will check the password
      # only of the *first* dn returned.  Email addresses can match
      # multiple dn's, so we keep looking.
      @ldap.search(:base => base, 
        :scope => Net::LDAP::SearchScope_WholeSubtree,
        :filter => filter, 
        :attributes => [ ],
        :return_result => false) do |entry|
        count += 1
        @ldap.auth(entry.dn, passwd)
        if @ldap.bind
          authenticated_entry = entry
          break
        end
        puts "bind failed for #{entry.dn}, #{passwd}"
      end
      if count == 0
        puts "no such user: #{filter.inspect}"
      end
    rescue Net::LDAP::LdapError => e
      # improper ldap operation
      puts "exception: #{e}"
    end
    authenticated_entry
  end
  
  def sync_container(container, ldif_file)
    # Container and ldif_file should operate on the same subtree

    # Remove a subtree of the users container
    @ldap.auth(@admin_dn, @admin_pw)
    count = 0
    @ldap.search(:base => container, 
      :scope => Net::LDAP::SearchScope_WholeSubtree,
      :attributes => [ ],
      :return_result => false) do |entry|
        count += 1
        puts "deleting #{entry.dn}"
        @ldap.delete(:dn => entry.dn)
    end
    
    # Blast the additions in using ldapmodify
    args = [ LdapAuthenticator.ldapmodify_path, '-c', '-x', '-D', @admin_dn, '-w', @admin_pw, '-f', ldif_file ]
    IO.popen(args.join(" "), 'r') do |f|
      puts f.gets
    end
  end
end
