class CreateEmployees < ActiveRecord::Migration
  def self.up
    create_table :employees, :id => false do |t|
      t.integer  :teachernumber
      t.string   :first_name
      t.string   :last_name
      t.integer  :status
      t.integer  :staffstatus
      t.string   :title
      t.integer  :schoolid
      t.string   :network_id
      t.string   :network_password
      t.string   :email_addr
      
      t.timestamps
    end
    
    Employee.load!
  end

  def self.down
    drop_table :employees
  end
end
