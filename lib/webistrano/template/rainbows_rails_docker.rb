# encoding: utf-8
module Webistrano
  module Template
    module RainbowsRailsDocker

      # hosts 若有必要，需要加入 aliyun_db 角色
      CONFIG = Webistrano::Template::RainbowsRails::CONFIG.dup.merge({
        :aliyun_access_key_id     => '访问阿里云API的密钥ID',
        :aliyun_secret_access_key => '访问阿里云API的密钥',
        :aliyun_ess_name          => '阿里云 ESS 伸缩组名称',
        :docker_startup_script    => 'you should overwrite this item in a recipe.',
        :docker_repository        => 'docker 镜像地址',
        :docker_container_name    => 'docker 容器别名',
        :docker_db_repository     => 'DB角色 docker 镜像地址',
        :docker_db_container_name => 'DB角色 docker 容器别名'
      }).freeze

      DESC = <<-'EOS'
        Template for use of Rainbows projects irrespective of web server on top.

        Overrides the deploy.restart, deploy.start, and deploy.stop tasks to use
        rainbows signals instead.
      EOS

      TASKS = Webistrano::Template::Base::TASKS + <<-'EOS'
        namespace :webistrano do
          namespace :docker do
            task :restart, :roles => [:aliyun_app], :except => { :no_release => true } do
              script = docker_startup_script.split("\n").select{|e| e.strip !~ /^#/ }.join(";")
              arg1 = docker_repository # or the key: rollback
              arg2 = docker_container_name
              script.gsub!('$1', arg1)
              script.gsub!('$2', arg2)
              
              logger.trace "** running docker script:\n"+script
              #invoke_command script, :via => run_method, :as => fetch(:runner, :aliyun_app)
            end
            
            task :restart_db, :roles => [:aliyun_db], :except => { :no_release => true } do
              script = docker_startup_script.split("\n").select{|e| e.strip !~ /^#/ }.join(";")
              arg1 = docker_db_repository # or the key: rollback
              arg2 = docker_db_container_name
              script.gsub!('$1', arg1)
              script.gsub!('$2', arg2)
              
              logger.trace "** running docker script:\n"+script
              invoke_command script, :via => run_method, :as => fetch(:runner, :aliyun_db)
            end
          end
        end
        
        before 'deploy' do
          # dynamic create aliyun role with ess hosts
          ess = Webistrano::Aliyun::Ess.new(aliyun_ess_name, :access_key_id => aliyun_access_key_id, :secret_access_key => aliyun_secret_access_key)
          
          ips = ess.public_ips
          ips.each{|ip| roles[:aliyun_app] << ip }
          
          logger.trace "ESS: #{aliyun_ess_name}, instances: #{ips}"
        end
        
        after 'deploy' do
          # restart docker container
          logger.trace "* docker executing: restart"
          webistrano.docker.restart_db
          webistrano.docker.restart
        end
      EOS

    end
  end
end
