class CreateReportCards < ActiveRecord::Migration
  def self.up
    create_table :report_cards do |t|
      t.integer :student_id, :null => false, :default => 0
      t.string  :year, :length => 4, :null => false
      t.string  :term, :length => 2, :null => false
      t.boolean :non_custodial, :null => false, :default => false
      t.text    :encoded_content
      t.timestamps
    end
  end

  def self.down
    drop_table :report_cards
  end
end
