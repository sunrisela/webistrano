class AddAliasNameColumnToHosts < ActiveRecord::Migration
  def up
    add_column :hosts, :alias_name, :string
  end
  
  def down
    remove_column :hosts, :alias_name
  end
end
