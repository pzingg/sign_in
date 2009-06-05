class Employee < ActiveRecord::Base
  set_primary_key :teachernumber
  cattr_accessor :ldap_container
  
  def full_name
    [first_name, last_name].compact.join(" ")
  end
  
  def current?
    self.status == 1
  end
  
  def employee_type
    e_stat = (staffstatus < 0 || staffstatus > 4) ? 0 : staffstatus
    ['special', 'teacher', 'staff', 'lunch staff', 'substitute'][staffstatus]
  end

  def ldif(ldap_container)
    employee_ldif = ''
    if !self.network_id.blank? && !self.network_password.blank? && !self.email_addr.blank?
      # case-insensitive rules
      uid = self.network_id.downcase
      user_password = self.network_password.downcase
      ou = ldap_container.match(/^ou=([^,]+)/)
      ou = ou[1] if ou
      employee_ldif = <<END_LDIF
dn: uid=#{uid},#{ldap_container}
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
employeeType: #{employee_type}
uid: #{uid}
userPassword: #{ldif_escape(user_password)}
sn: #{ldif_escape(last_name)}
givenName: #{ldif_escape(first_name)}
cn: #{ldif_escape(full_name)}
employeeNumber: #{teachernumber}
departmentNumber: #{schoolid}
mail: #{ldif_escape(email_addr)}
END_LDIF

      employee_ldif << "ou: #{ou}\n" if ou
      employee_ldif << "title: #{ldif_escape(title)}\n" if title
      employee_ldif << "\n"
    end
    
    employee_ldif
  end
  
  class << self
    def has_attribute?(key)
      column_names.include?(key.to_s)
    end
    
    def current_employees
      find(:all, :conditions => ['status=1'])
    end

    def load!
      fname = "export.txt"
      fname = File.join(Rails.root, "data", fname) unless fname[0,1] == '/'
      csv_options = { :col_sep => "\t", :row_sep => "\n" }
      csv_options[:headers] = true
      csv_options[:header_converters] = :symbol
      count = 0
      UnquotedCSV.foreach(fname, csv_options) do |row|
        count += 1
        attrs = row.to_hash
        import_employee(attrs)
      end
      count
    end

    def import_employee(attrs)
      employee_attrs = attrs.reject { |k, v| !has_attribute?(k) }

      int_convert(employee_attrs, :teachernumber)
      teachernumber = employee_attrs.delete(:teachernumber)

      int_convert(employee_attrs, :status)
      int_convert(employee_attrs, :staffstatus)
      int_convert(employee_attrs, :schoolid)
      email_convert(employee_attrs, :email_addr)

      emp = Employee.new(employee_attrs)
      emp.id = teachernumber
      emp.save
      puts "saved #{emp.inspect}"
    end

    def generate_ldif
      ou = ldap_container.match(/^ou=([^,]+)/)[1]
      employee_ldif = <<END_LDIF
dn: #{ldap_container}
changetype: add
objectclass: top
objectclass: organizationalUnit
ou: #{ou}
description: Staff open directory logins

END_LDIF

      fname = "employees.ldif"
      fname = File.join(Rails.root, "ldif", fname) unless fname[0,1] == '/'
      File.open(fname, "w") do |f|
        f.write(employee_ldif)
        current_employees.each do |emp|
          f.write(emp.ldif(ldap_container))
        end
      end
    end
  end
end
