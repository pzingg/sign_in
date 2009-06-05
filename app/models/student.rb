class Student < ActiveRecord::Base
  has_many :report_cards, :order => 'year,term,non_custodial'
  set_primary_key :student_number
  cattr_accessor :ldap_student_container, :ldap_guardian_container
  
  def full_name
    [first_name, last_name].compact.join(" ")
  end
  
  def family_students
    Student.family_students(self.home_id, self.home2_id)
  end
  
  def family_emails
    Student.family_emails(self.home_id, self.home2_id)
  end
  
  def has_sibling?(student_id)
    family_students.collect { |fstu| fstu.id }.include?(student_id)
  end
  
  def current?
    self.enroll_status <= 0
  end
  
  def ldif(guardian_container, student_container)
    guardian_ldif = ''
    if !self.web_id.blank? && !self.web_password.blank?
      # case-insensitive rules
      uid = self.web_id.downcase
      user_password = self.web_password.downcase
      ou = guardian_container.match(/^ou=([^,]+)/)
      ou = ou[1] if ou
      guardian_ldif = <<END_LDIF
dn: uid=#{uid},#{guardian_container}
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
employeeType: guardian
uid: #{uid}
userPassword: #{ldif_escape(user_password)}
sn: #{ldif_escape(full_name)}
givenName: Guardian of
cn: Guardian of #{ldif_escape(full_name)}
employeeNumber: #{student_number}
departmentNumber: #{grade_level}
END_LDIF

      guardian_ldif << "ou: #{ou}\n" if ou
      family_emails.each do |email|
        guardian_ldif << "mail: #{ldif_escape(email)}\n"
      end
      guardian_ldif << "\n"
    end

    student_ldif = ''
    if !self.network_id.blank? && !self.network_password.blank?
      uid = self.network_id.downcase
      user_password = self.network_password.downcase
      ou = student_container.match(/^ou=([^,]+)/)
      ou = ou[1] if ou
      student_ldif = <<END_LDIF
dn: uid=#{uid},#{student_container}
changetype: add
objectClass: top
objectClass: person
objectClass: organizationalPerson
objectClass: inetOrgPerson
employeeType: student
uid: #{uid}
userPassword: #{ldif_escape(user_password)}
sn: #{ldif_escape(last_name)}
givenName: #{ldif_escape(first_name)}
cn: #{ldif_escape(full_name)}
employeeNumber: #{student_number}
departmentNumber: #{grade_level}
END_LDIF

      student_ldif << "ou: #{ou}\n" if ou
      student_ldif << "\n"
    end
  
    guardian_ldif + student_ldif
  end  

  class << self
    def has_attribute?(key)
      column_names.include?(key.to_s)
    end
    
    def current_students
      find(:all, :conditions => ['enroll_status<=0'])
    end
    
    def load!
      fname = "student.export.text"
      fname = File.join(Rails.root, "data", fname) unless fname[0,1] == '/'
      csv_options = { :col_sep => "\t", :row_sep => "\n" }
      csv_options[:headers] = true
      csv_options[:header_converters] = :symbol
      count = 0
      UnquotedCSV.foreach(fname, csv_options) do |row|
        count += 1
        attrs = row.to_hash
        import_student(attrs)
      end
      count
    end
    
    def import_student(attrs)
      student_attrs = attrs.reject { |k, v| !has_attribute?(k) }
      
      int_convert(student_attrs, :student_number)
      student_number = student_attrs.delete(:student_number)
      
      int_convert(student_attrs, :home_id)
      int_convert(student_attrs, :home2_id)
      int_convert(student_attrs, :enroll_status)
      int_convert(student_attrs, :schoolid)
      int_convert(student_attrs, :grade_level)
      email_convert(student_attrs, :mother_email)
      email_convert(student_attrs, :father_email)
      email_convert(student_attrs, :mother2_email)
      email_convert(student_attrs, :father2_email)
      
      stu = Student.new(student_attrs)
      stu.id = student_number
      stu.save
      puts "saved #{stu.inspect}"
    end
    
    def family_students(*home_ids)
      find(:all, 
        :conditions => ['(home_id<>0 AND home_id IN (?)) OR (home2_id<>0 AND home2_id IN (?))', home_ids, home_ids],
        :order => ['last_name,first_name'])
    end
    
    def family_emails(*home_ids)
      emails = family_students.inject({}) do |h, stu|
        h[stu.mother_email] = 1 if stu.mother_email
        h[stu.father_email] = 1 if stu.father_email
        h[stu.mother2_email] = 1 if stu.mother2_email
        h[stu.father2_email] = 1 if stu.father2_email
        h
      end.keys
    end
    
    def generate_ldif
      ou = ldap_student_container.match(/^ou=([^,]+)/)[1]
      student_ldif = <<END_LDIF
dn: #{ldap_student_container}
changetype: add
objectclass: top
objectclass: organizationalUnit
ou: #{ou}
description: Student open directory logins

END_LDIF

      ou = ldap_guardian_container.match(/^ou=([^,]+)/)[1]
      guardian_ldif = <<END_LDIF
dn: #{ldap_guardian_container}
changetype: add
objectclass: top
objectclass: organizationalUnit
ou: #{ou}
description: PowerSchool guardian logins

END_LDIF

      fname = "students.ldif"
      fname = File.join(Rails.root, "ldif", fname) unless fname[0,1] == '/'
      File.open(fname, "w") do |f|
        f.write(student_ldif)
        f.write(guardian_ldif)
        current_students.each do |stu|
          f.write(stu.ldif(ldap_guardian_container, ldap_student_container))
        end
      end
    end
  end
end
