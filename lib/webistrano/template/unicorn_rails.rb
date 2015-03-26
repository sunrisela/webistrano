module Webistrano
  module Template
    module UnicornRails

      CONFIG = Webistrano::Template::Rails::CONFIG.dup.merge({
        :unicorn_bin    => 'bundle exec unicorn_rails',
        :unicorn_config => "config/unicorn.rb",
        :unicorn_pid    => 'tmp/pids/unicorn.pid'
      }).freeze

      DESC = <<-'EOS'
        Template for use of Unicorn projects irrespective of web server on top.

        Overrides the deploy.restart, deploy.start, and deploy.stop tasks to use
        unicorn signals instead.
      EOS

      TASKS = Webistrano::Template::Base::TASKS + <<-'EOS'

        cmds = {
          start:   "#{unicorn_bin} -c #{unicorn_config} -E #{rails_env} -D",
          stop:    "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -QUIT `cat #{unicorn_pid}`; fi"
        }
        
        cmds[:restart] = "#{cmds[:stop]} && #{cmds[:start]}"
        cmds[:reload]  = "if [ -f #{unicorn_pid} ] && [ -e /proc/$(cat #{unicorn_pid}) ]; then kill -USR2 `cat #{unicorn_pid}`; else #{cmds[:start]}; fi"

        namespace :webistrano do
          namespace :unicorn do
            [ :start, :stop, :restart, :reload ].each do |t|
              desc "#{t.to_s.capitalize} unicorn"
              task t, :roles => :app, :except => { :no_release => true } do
                as = fetch(:runner, "app")
                invoke_command "cd #{current_path}; #{cmds[t]}", :via => run_method, :as => as
              end
            end
          end
        end

        namespace :deploy do
          task :start, :roles => :app, :except => { :no_release => true } do
            webistrano.unicorn.start
          end
          
          task :stop, :roles => :app, :except => { :no_release => true } do
            webistrano.unicorn.stop
          end
          
          task :restart, :roles => :app, :except => { :no_release => true } do
            webistrano.unicorn.restart
          end
          
          task :reload, :roles => :app, :except => { :no_release => true } do
            webistrano.unicorn.reload
          end
        end
      EOS

    end
  end
end