class CreateStudents < ActiveRecord::Migration
  def self.up
    create_table :students, :id => false do |t|
      t.integer :student_number
      t.string  :first_name
      t.string  :last_name
      t.integer :enroll_status
      t.integer :schoolid
      t.integer :grade_level
      t.integer :home_id
      t.integer :home2_id
      t.string  :network_id
      t.string  :network_password
      t.string  :web_id
      t.string  :web_password
      t.string  :mother_email
      t.string  :father_email
      t.string  :mother2_email
      t.string  :father2_email
      t.timestamps
    end
    
    Student.load!
  end

  def self.down
    drop_table :students
  end
end
