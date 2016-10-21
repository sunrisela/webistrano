class Deployment < ActiveRecord::Base

  DEPLOY_TASKS    = ['deploy', 'deploy:default', 'deploy:migrations']
  SETUP_TASKS     = ['deploy:setup']
  STATUS_CANCELED = "canceled"
  STATUS_FAILED   = "failed"
  STATUS_SUCCESS  = "success"
  STATUS_RUNNING  = "running"
  STATUS_VALUES   = [STATUS_SUCCESS, STATUS_FAILED, STATUS_CANCELED, STATUS_RUNNING]

  scope :recent, proc { |*args|
    max = args.first || 3
    reorder('deployments.created_at DESC').limit(max)
  }

  belongs_to :stage
  belongs_to :user
  has_and_belongs_to_many :roles

  validates :task, :stage, :user,
    :presence => true
  validates :task,
    :length => { :maximum => 250 }
  validates :status,
    :inclusion => { :in => STATUS_VALUES }
  validate :guard_readiness_of_stage, :on => :create

  serialize :excluded_host_ids

  attr_accessible :task, :prompt_config, :description, :excluded_host_ids, :override_locking

  # given configuration hash on create in order to satisfy prompt configurations
  attr_accessor :prompt_config

  attr_accessor :override_locking

  after_create :add_stage_roles

  def self.lock_and_fire(&block)
    transaction do
      d = Deployment.new
      block.call(d)
      return false unless d.valid?
      stage = Stage.find(d.stage_id, :lock => true)
      stage.lock
      d.save!
      stage.lock_with(d)
    end
    true
  rescue => e
    Rails.logger.debug "DEPLOYMENT: could not fire deployment: #{e.inspect} #{e.backtrace.join("\n")}"
    false
  end

  def override_locking?
    @override_locking.to_i == 1
  end

  def prompt_config
    @prompt_config = @prompt_config || {}
    @prompt_config
  end

  def effective_and_prompt_config
    @effective_and_prompt_config = @effective_and_prompt_config || self.stage.effective_configuration.collect do |conf|
      if prompt_config.has_key?(conf.name)
        conf.value = prompt_config[conf.name]
      end
      conf
    end
  end

  def add_stage_roles
    self.stage.roles.each do |role|
      self.roles << role
    end
  end

  def completed?
    !self.completed_at.blank?
  end

  def success?
    self.status == STATUS_SUCCESS
  end

  def failed?
    self.status == STATUS_FAILED
  end

  def canceled?
    self.status == STATUS_CANCELED
  end

  def running?
    self.status == STATUS_RUNNING
  end

  def status_in_html
    "<span class='deployment_status_#{self.status.gsub(/ /, '_')}'>#{self.status}</span>"
  end

  def complete_with_error!
    save_completed_status!(STATUS_FAILED)
    notify_per_mail
  end

  def complete_successfully!
    save_completed_status!(STATUS_SUCCESS)
    notify_per_mail
  end

  def complete_canceled!
    save_completed_status!(STATUS_CANCELED)
    notify_per_mail
  end

  # deploy through Webistrano::Deployer in background (== other process)
  # TODO - at the moment `Unix &` hack
  def deploy_in_background!
    unless Rails.env.test?
      Rails.logger.info "Calling other ruby process in the background in order to deploy deployment #{self.id} (stage #{self.stage.id}/#{self.stage.name})"

      system("sh -c \"cd #{Rails.root} && rails runner -e #{Rails.env} ' deployment = Deployment.find(#{self.id}); deployment.prompt_config = #{self.prompt_config.inspect.gsub('"', '\"')} ; Webistrano::Deployer.new(deployment).invoke_task! ' >> #{Rails.root}/log/#{Rails.env}.log 2>&1\" &")
    end
  end

  # returns an unsaved, new deployment with the same task/stage/description
  def repeat
    Deployment.new.tap do |d|
      d.stage = self.stage
      d.task = self.task
      d.description = "Repetition of deployment #{self.id}: \n"
      d.description += self.description
    end
  end

  # returns a list of hosts that this deployment
  # will deploy to. This computed out of the list
  # of given roles and the excluded hosts
  def deploy_to_hosts
    all_hosts = self.roles.map(&:host).uniq
    return all_hosts - self.excluded_hosts
  end

  # returns a list of roles that this deployment
  # will deploy to. This computed out of the list
  # of given roles and the excluded hosts
  def deploy_to_roles(base_roles=self.roles)
    base_roles.dup.delete_if{|role| self.excluded_hosts.include?(role.host) }
  end

  # a list of all excluded hosts for this deployment
  # see excluded_host_ids
  def excluded_hosts
    res = []
    self.excluded_host_ids.each do |h_id|
      res << (Host.find(h_id) rescue nil)
    end
    res.compact
  end

  def excluded_host_ids
    self['excluded_host_ids'].blank? ? [] : self['excluded_host_ids']
  end

  def excluded_host_ids=(val)
    val = [val] unless val.is_a?(Array)
    self['excluded_host_ids'] = val.map(&:to_i)
  end

  def cancelling_possible?
    self.pid.present? and !completed?
  end

  def cancel!
    unless cancelling_possible?
      raise "Canceling not possible: Either no PID or already completed"
    end

    Process.kill("SIGINT", self.pid)
    sleep 2
    Process.kill("SIGKILL", self.pid) rescue nil # handle the case that we killed the process the first time

    complete_canceled!
  end

  def clear_lock_error
    self.errors.delete('lock')
  end

protected

  def save_completed_status!(status)
    if self.completed?
      raise 'cannot complete a second time'
    end

    transaction do
      stage = Stage.find(self.stage_id, :lock => true)
      stage.unlock
      self.status = status
      self.completed_at = Time.now
      self.save!
    end
  end

  def notify_per_mail
    self.stage.emails.each do |email|
      Notification.deployment(self, email).deliver
    end
  end

private

  # check (on on creation ) that the stage is ready
  # his has to done only on creation as later DB logging MUST always work
  def guard_readiness_of_stage
    unless self.stage.blank?

      unless self.stage.deployment_possible?
        errors.add('stage', 'is not ready to deploy')
      end

      self.stage.prompt_configurations.each do |conf|
        if prompt_config.blank? or prompt_config[conf.name.to_sym].blank?
          errors.add('base', "Please fill out the parameter '#{conf.name}'")
        end
      end

      if self.stage.locked? && !self.override_locking
        errors.add('lock', 'The stage is locked')
      end

      if self.stage.present? and self.excluded_host_ids.present? and deploy_to_roles(self.stage.roles).blank?
        errors.add('base', "You cannot exclude all hosts.")
      end

    end
  end

end
