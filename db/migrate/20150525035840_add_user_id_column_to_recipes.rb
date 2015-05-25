class AddUserIdColumnToRecipes < ActiveRecord::Migration
  def up
    add_column :recipes, :user_id, :integer
  end
  
  def down
    remove_column :recipes, :user_id
  end
end
