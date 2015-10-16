class AddSshUserColumnToRoles < ActiveRecord::Migration
  def up
    add_column :roles, :ssh_user, :string
  end
  
  def down
    remove_column :roles, :ssh_user
  end
end
