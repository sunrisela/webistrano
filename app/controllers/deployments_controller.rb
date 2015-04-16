class DeploymentsController < ApplicationController
  respond_to :html, :xml, :json

  before_filter :load_stage
  before_filter :ensure_deployment_possible, :only => [:new, :create]

  # GET /projects/1/stages/1/deployments
  # GET /projects/1/stages/1/deployments.xml
  def index
    @deployments = @stage.deployments
    respond_with(@deployments)
  end

  # GET /projects/1/stages/1/deployments/1
  # GET /projects/1/stages/1/deployments/1.xml
  def show
    @deployment = @stage.deployments.find(params[:id])
    set_auto_scroll
    @log_from = params[:log_from].to_i
    response.headers['Deployment-Completed'] = "1" if @deployment.completed?
    respond_with(@deployment) do |format|
      format.js { render :partial => 'log' }
    end
  end

  # GET /projects/1/stages/1/deployments/new
  def new
    if params[:repeat]
      @original = @stage.deployments.find(params[:repeat])
      @deployment = @original.repeat
    else
      @deployment = @stage.deployments.new
      @deployment.task = params[:task]
    end

    respond_with(@deployment)
  end

  # POST /projects/1/stages/1/deployments
  # POST /projects/1/stages/1/deployments.xml
  def create
    @deployment = Deployment.new

    if populate_deployment_and_fire
      @deployment.deploy_in_background!
      respond_with(@deployment, :location => [@project, @stage, @deployment])
    else
      @deployment.clear_lock_error
      respond_with(@deployment)
    end
  end

  # GET /projects/1/stages/1/deployments/latest
  def latest
    @deployment = @stage.deployments.find(:first, :order => "created_at desc")
    if @deployment
      redirect_to([@project, @stage, @deployment])
    else
      render :status => :not_found, :nothing => true
    end
  end

  # POST /projects/1/stages/1/deployments/1/cancel
  def cancel
    @deployment = @stage.deployments.find(:first, :order => "created_at desc")

    begin
      @deployment.cancel!
      flash[:notice] = "Cancelled deployment by killing it"
      respond_with(@deployment, :location => [@project, @stage, @deployment])

    rescue => e
      flash[:error] = "Cancelling failed: #{e.message}"
      @deployment.errors.add("base", e.message)
      respond_with(@deployment, :location => [@project, @stage, @deployment])
    end
  end

  protected
  def ensure_deployment_possible
    if current_stage.deployment_possible?
        true
    else
      respond_to do |format|
        flash[:error] = 'A deployment is currently not possible.'
        format.html { redirect_to project_stage_url(@project, @stage) }
        format.xml  { render :xml => current_stage.deployment_problems.to_xml }
        false
      end
    end
  end

  def set_auto_scroll
    if params[:auto_scroll].to_s == "true"
      @auto_scroll = true
    else
      @auto_scroll = false
    end
  end

  # sets @deployment
  def populate_deployment_and_fire
    return Deployment.lock_and_fire do |deployment|
      deployment_params = params[:deployment] || {}
      prompt_config     = deployment_params[:prompt_config] || {}

      @deployment = deployment
      @deployment.attributes    = deployment_params
      @deployment.prompt_config = prompt_config
      @deployment.stage = current_stage
      @deployment.user = current_user
    end
  end

end
