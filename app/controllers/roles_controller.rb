class RolesController < ApplicationController
  respond_to :html, :xml, :json
  
  before_filter :load_stage
  before_filter :load_host_choices, :only => [:new, :edit, :update, :create]
  
  # GET /projects/1/stages/1/roles/1
  # GET /projects/1/stages/1/roles/1.xml
  def show
    @role = @stage.roles.find(params[:id])

    respond_with(@role)
  end

  # GET /projects/1/stages/1/roles/new
  def new
    @role = @stage.roles.new
    respond_with(@role)
  end

  # GET /projects/1/stages/1/roles/1;edit
  def edit
    @role = @stage.roles.find(params[:id])
    respond_with(@role)
  end

  # POST /projects/1/stages/1/roles
  # POST /projects/1/stages/1/roles.xml
  def create
    @role = @stage.roles.build(params[:role])

    if @role.save
      flash[:notice] = 'Role was successfully created.'
      respond_with(@role, :location => [@project, @stage])
    else
      respond_with(@role)
    end
  end

  # PUT /projects/1/stages/1/roles/1
  # PUT /projects/1/stages/1/roles/1.xml
  def update
    @role = @stage.roles.find(params[:id])

    if @role.update_attributes(params[:role])
      flash[:notice] = 'Role was successfully updated.'
      respond_with(@role, :location => [@project, @stage])
    else
      respond_with(@role)
    end
  end

  # DELETE /projects/1/stages/1/roles/1
  # DELETE /projects/1/stages/1/roles/1.xml
  def destroy
    @role = @stage.roles.find(params[:id])
    @role.destroy

    flash[:notice] = 'Role was successfully deleted.'
    respond_with(@role, :location => [@project, @stage])
  end
  
private

  def load_host_choices
    @host_choices = Host.order("name ASC").collect {|h| [ h.alias_name.present? ? "#{h.name} (#{h.alias_name})" : h.name, h.id ] }
  end
  
end
