class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table(:users) do |t|
      t.string   :email
      t.string   :encrypted_password, :limit => 128
      t.string   :salt,               :limit => 128
      t.string   :token,              :limit => 128
      t.datetime :token_expires_at
      t.boolean  :email_confirmed, :null => false, :default => false
      t.boolean  :active,          :null => false, :default => false
      t.boolean  :permanent,       :null => false, :default => false
      t.boolean  :admin,           :null => false, :default => false
      t.string   :ldap_dn, :limit => 128
      t.string   :ldap_person_type
      t.integer  :student_number,  :null => false, :default => 0
      t.integer  :teachernumber,   :null => false, :default => 0
      t.integer  :home_id,         :null => false, :default => 0
      t.integer  :parent_position, :null => false, :default => 0
      t.integer  :schoolid,        :null => false, :default => 0
      t.datetime :updated_from_ldap_at
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :users, [:id, :token]
    add_index :users, :email
    add_index :users, :token    
    
    user = User.create(:email => User.admin_email, :password => User.admin_pw)
    user.email_confirmed = true
    user.active          = true
    user.permanent       = true
    user.admin           = true
    user.save
  end
  
  def self.down
    drop_table :users  
  end
end
