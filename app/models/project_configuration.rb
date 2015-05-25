class ProjectConfiguration < ConfigurationParameter
  belongs_to :project

  validates :project,
    :presence => true
  validates :name, 
    :uniqueness => { :scope => :project_id }

  # default templates for Projects
  def self.templates
    {
      'rails'          => Webistrano::Template::Rails,
      'mongrel_rails'  => Webistrano::Template::MongrelRails,
      'thin_rails'     => Webistrano::Template::ThinRails,
      'mod_rails'      => Webistrano::Template::ModRails,
      'pure_file'      => Webistrano::Template::PureFile,
      'unicorn_rails'  => Webistrano::Template::UnicornRails,
      'rainbows_rails' => Webistrano::Template::RainbowsRails,
      'rainbows_rails_docker' => Webistrano::Template::RainbowsRailsDocker
    }
  end

end
