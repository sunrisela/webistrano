# encoding: utf-8
module Webistrano
  module Template
    module RainbowsRailsDocker

      # hosts 若有必要，需要加入 aliyun_db 角色
      CONFIG = Webistrano::Template::RainbowsRails::CONFIG.dup.merge({
        :aliyun_user              => 'root',
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
        start_docker_cmd_blk = lambda do
          script = docker_startup_script.dup
          
          script.gsub!('$1', docker_repository)
          script.gsub!('$2', docker_container_name)
          
          # 过滤注释
          script.gsub!(/^#.*$/,'')
          # \
          script.gsub!(/\\[\s]+/, '')
          # then
          script.gsub!(/then[\s]+/, 'then ')
          # else
          script.gsub!(/else[\s]*[\r\n]+[\s]*/, 'else ')
          # fi
          script.gsub!(/[\r\n]+[\s]*fi/,'; fi')
          # do
          script.gsub!(/do[\s]*[\r\n]+[\s]*/, 'do ')
          # done
          script.gsub!(/[\r\n]+[\s]*done/,'; done')
          
          script.split(/[\r\n]+/).map{|e| str=e.strip; str if !str.blank? }.compact.join(" && ")
        end
        
        namespace :webistrano do
          namespace :docker do
            task :restart, :roles => [:aliyun_app] do
              invoke_command start_docker_cmd_blk.call
            end
          end
        end
        
        before 'deploy' do
          role = roles.delete(:aliyun_db)
          hosts = role ? role.servers.map(&:host) : []
          set :aliyun_db_hosts, hosts
        end
        
        after 'deploy' do
          # restart docker container
          logger.trace "* docker executing: restart"
          
          run start_docker_cmd_blk.call, :hosts => aliyun_user ? aliyun_db_hosts.map{|e| "#{aliyun_user}@#{e}" } : aliyun_db_hosts
          
          # dynamic create aliyun role with ess hosts
          if aliyun_ess_name.present?
            ess = Webistrano::Aliyun::Ess.new(aliyun_ess_name, :access_key_id => aliyun_access_key_id, :secret_access_key => aliyun_secret_access_key)
            ips = ess.public_ips
            ips = ips - aliyun_db_hosts
            roles[:aliyun_app].push *ips, { :user => aliyun_user }
  
            logger.trace "ESS: #{aliyun_ess_name}, instances: #{ips}"
            
            webistrano.docker.restart
          end
          
        end
      EOS

    end
  end
end
