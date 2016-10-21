class AddMissingIndexes < ActiveRecord::Migration
  def up
    add_index :recipes_stages, [:recipe_id, :stage_id]
    add_index :stages, [:project_id, :name]
    add_index :stages, :locked_by_deployment_id
    add_index :configuration_parameters, [:id, :type]
    add_index :configuration_parameters, [:project_id, :type, :name]
    add_index :configuration_parameters, :stage_id
    add_index :deployments, [:stage_id, :created_at]
    add_index :deployments, :user_id
    add_index :deployments_roles, [:deployment_id, :role_id]
    add_index :deployments, [:task, :status]
    add_index :recipe_versions, :recipe_id
    add_index :roles, [:stage_id, :name]
    add_index :roles, :host_id
    add_index :hosts, :name
    add_index :projects, :name
    add_index :recipes, :name
  end

  def down
    remove_index :recipes_stages, column: [:recipe_id, :stage_id]
    remove_index :stages, column: [:project_id, :name]
    remove_index :stages, column: :locked_by_deployment_id
    remove_index :configuration_parameters, column: [:id, :type]
    remove_index :configuration_parameters, column: [:project_id, :type, :name]
    remove_index :configuration_parameters, column: :stage_id
    remove_index :deployments, column: [:stage_id, :created_at]
    remove_index :deployments, column: :user_id
    remove_index :deployments_roles, column: [:deployment_id, :role_id]
    remove_index :deployments, column: [:task, :status]
    remove_index :recipe_versions, column: :recipe_id
    remove_index :roles, column: [:stage_id, :name]
    remove_index :roles, column: :host_id
    remove_index :hosts, column: :name
    remove_index :projects, column: :name
    remove_index :recipes, column: :name
  end
end
