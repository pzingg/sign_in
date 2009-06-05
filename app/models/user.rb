class User < ActiveRecord::Base
  cattr_accessor :admin_email, :admin_pw,
    :ldap_host, :ldap_port, :ldap_admin_dn, :ldap_admin_pw, :ldap_base
  
  attr_accessible :email, :password, :password_confirmation
  attr_accessor           :password, :password_confirmation

  validates_presence_of     :email
  validates_uniqueness_of   :email, :case_sensitive => false
  validates_format_of       :email, :with => %r{.+@.+\..+}

  validates_presence_of     :password, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?

  before_save :initialize_salt, :encrypt_password, :initialize_token
  
  def any_report_cards?
    students.each do |stu|
      return true if stu.report_cards.count > 0
    end
    false
  end
  
  def students
    return [ ] unless self.ldap_person_type == 'guardian' && self.student_number != 0
    stu = Student.find(self.student_number)
    stu.family_students
  end
  
  def student_access_for?(student_id)
    return false unless self.ldap_person_type == 'guardian' && self.student_number != 0
    stu = Student.find(self.student_number)
    student_id = student_id.student_number if student_id.is_a? Student
    stu.has_sibling?(student_id)
  end
  
  def authenticated_by_database?(passwd)
    encrypted_password == encrypt(passwd)
  end

  def authenticated_by_ldap?(passwd)
    return User.authenticate_by_ldap(email, passwd)
  end
  
  def authenticated?(passwd)
    authenticated_by_database?(passwd) || authenticated_by_ldap?(passwd)
  end

  # all these functions from thoughtbot-clearance
  def encrypt(string, preserve_case=false)
    string.downcase! if !preserve_case && User.case_insensitive_passwords?
    generate_hash("--#{salt}--#{string}--")
  end

  def remember?
    token_expires_at && Time.now.utc < token_expires_at
  end

  def remember_me!
    remember_me_until! 2.weeks.from_now.utc
  end

  def forget_me!
    clear_token
    save(false)
  end

  def confirm_email!
    self.email_confirmed  = true
    self.token            = nil
    save(false)
  end

  def forgot_password!
    generate_token
    save(false)
  end

  def update_password(new_password, new_password_confirmation)
    self.password              = new_password
    self.password_confirmation = new_password_confirmation
    clear_token if valid?
    save
  end

  protected

  def generate_hash(string)
    Digest::SHA1.hexdigest(string)
  end

  def initialize_salt
    if new_record?
      self.salt = generate_hash("--#{Time.now.utc.to_s}--#{password}--")
    end
  end

  def encrypt_password
    return if password.blank?
    self.encrypted_password = encrypt(password)
  end

  def generate_token
    self.token = encrypt("--#{Time.now.utc.to_s}--#{password}--", true)
    self.token_expires_at = nil
  end

  def clear_token
    self.token            = nil
    self.token_expires_at = nil
  end

  def initialize_token
    generate_token if new_record?
  end

  def password_required?
    encrypted_password.blank? || !password.blank?
  end

  def remember_me_until!(time)
    self.token_expires_at = time
    self.token = encrypt("--#{token_expires_at}--#{password}--", true)
    save(false)
  end

  class << self
    def authenticate_by_database(email, passwd)
      user = find_by_email(email)
      return [user, user && user.authenticated_by_database?(passwd)]
    end
    
    def case_insensitive_passwords?
      true
    end
    
    def ldap
      @ldap ||= LdapAuthenticator.new(User.ldap_host, User.ldap_port, User.ldap_admin_dn, User.ldap_admin_pw)
    end
    
    def authenticate_by_ldap(email, passwd)
      return nil if email.nil? || email.empty? || passwd.nil? || passwd.empty?
      passwd.downcase! if User.case_insensitive_passwords?
      filter = Net::LDAP::Filter.eq('mail', email)
      entry = ldap.authenticate(User.ldap_base, filter, passwd)
    end
    
    def authenticate(email, passwd)
      user, authenticated = authenticate_by_database(email, passwd)
      return user if authenticated
      entry = authenticate_by_ldap(email, passwd)
      return nil unless entry
      
      begin
        person_type = entry['employeeType'][0]
        
        # Can throw exception if email has different password!
        if user
          user.password = passwd
        else
          user = User.create(:email => email, :password => passwd)
          user.email_confirmed = true
        end

        user.updated_from_ldap_at = user.updated_at
        user.active           = true
        user.ldap_dn          = entry.dn
        user.ldap_person_type = person_type
        if person_type == 'guardian'
          user.student_number = entry['employeeNumber'][0].to_i
        end
        user.save
        puts "updating user #{user.email}"
      rescue
        puts "authentication exception: #{$!}"
        user = nil
      end
      user
    end
  end
end
