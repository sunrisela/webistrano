class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string    :login
      t.boolean   :admin, :default => false
      t.string    :time_zone, :default => 'Asia/Shanghai'
      t.timestamp :disabled_at
    end
    
    add_index :users, :disabled_at
  end

  def self.down
    drop_table :users
  end
end
