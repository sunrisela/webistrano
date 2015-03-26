module Webistrano
  module Template
    module RainbowsRails

      CONFIG = Webistrano::Template::Rails::CONFIG.dup.merge({
        :rainbows_bin    => 'bundle exec rainbows',
        :rainbows_config => "config/rainbows.rb",
        :rainbows_pid    => 'tmp/pids/rainbows.pid'
      }).freeze

      DESC = <<-'EOS'
        Template for use of Rainbows projects irrespective of web server on top.

        Overrides the deploy.restart, deploy.start, and deploy.stop tasks to use
        rainbows signals instead.
      EOS

      TASKS = Webistrano::Template::Base::TASKS + <<-'EOS'

        cmds = {
          start:   "#{rainbows_bin} -c #{rainbows_config} -E #{rails_env} -D",
          stop:    "if [ -f #{rainbows_pid} ] && [ -e /proc/$(cat #{rainbows_pid}) ]; then kill -QUIT `cat #{rainbows_pid}`; fi"
        }
        
        cmds[:restart] = "#{cmds[:stop]} && #{cmds[:start]}"
        cmds[:reload]  = "if [ -f #{rainbows_pid} ] && [ -e /proc/$(cat #{rainbows_pid}) ]; then kill -USR2 `cat #{rainbows_pid}`; else #{cmds[:start]}; fi"

        namespace :webistrano do
          namespace :rainbows do
            [ :start, :stop, :restart, :reload ].each do |t|
              desc "#{t.to_s.capitalize} rainbows"
              task t, :roles => :app, :except => { :no_release => true } do
                as = fetch(:runner, "app")
                invoke_command "cd #{current_path}; #{cmds[t]}", :via => run_method, :as => as
              end
            end
          end
        end

        namespace :deploy do
          task :start, :roles => :app, :except => { :no_release => true } do
            webistrano.rainbows.start
          end
          
          task :stop, :roles => :app, :except => { :no_release => true } do
            webistrano.rainbows.stop
          end
          
          task :restart, :roles => :app, :except => { :no_release => true } do
            webistrano.rainbows.restart
          end
          
          task :reload, :roles => :app, :except => { :no_release => true } do
            webistrano.rainbows.reload
          end
        end
      EOS

    end
  end
end
