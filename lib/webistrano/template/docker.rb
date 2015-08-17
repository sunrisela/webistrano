# encoding: utf-8
module Webistrano
  module Template
    module Docker
      CONFIG = {
        :application => 'your_app_name',
        :repository  => '.',
        :user        => 'root',
        :use_sudo    => 'false',
        :aliyun_access_key_id     => '访问阿里云API的密钥ID',
        :aliyun_secret_access_key => '访问阿里云API的密钥',
        :aliyun_ess_name          => '阿里云 ESS 伸缩组名称（若为空表示不启用ESS）',
        :docker_startup_script    => 'you should overwrite this item in a recipe.',
        :docker_repository        => 'docker 镜像地址',
        :docker_container_name    => 'docker 容器别名',
        :docker_db_repository     => 'DB角色 docker 镜像地址（若为空，默认为docker_repository）',
        :docker_db_container_name => 'DB角色 docker 容器别名（若为空，默认为docker_container_name）'
      }.freeze
      
      DESC = <<-'EOS'
        阿里云Docker部署模板.
      EOS
      
      TASKS =  <<-'EOS'
        # allocate a pty by default as some systems have problems without
        default_run_options[:pty] = true
      
        # set Net::SSH ssh options through normal variables
        # at the moment only one SSH key is supported as arrays are not
        # parsed correctly by Webistrano::Deployer.type_cast (they end up as strings)
        [:ssh_port, :ssh_keys].each do |ssh_opt|
          if exists? ssh_opt
            logger.important("SSH options: setting #{ssh_opt} to: #{fetch(ssh_opt)}")
            ssh_options[ssh_opt.to_s.gsub(/ssh_/, '').to_sym] = fetch(ssh_opt)
          end
        end
        
        
        if docker_db_repository.blank?
          docker_db_repository = docker_repository
        end
        if docker_db_container_name.blank?
          docker_db_container_name = docker_container_name
        end
        
        start_docker_cmd_blk = lambda do |repository, container_name|
          script = docker_startup_script.dup
          
          script.sub!('$1', repository)
          script.sub!('$2', container_name)
          
          # 过滤注释
          script.gsub!(/^#.*$/,'')
          # \
          script.gsub!(/\\[\s]+/, '')
          # then
          script.gsub!(/then[\s]+/, 'then ')
          # else
          script.gsub!(/[\r\n]+[\s]*else/,'; else')
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
            task :restart do
              restart_app
              restart_db   if roles[:db].present?
              restart_ess  if roles[:ess_app].present?
            end
            task :restart_app, :roles => [:app] do
              invoke_command start_docker_cmd_blk.call(docker_repository, docker_container_name)
            end
            task :restart_db, :roles => [:db] do
              invoke_command start_docker_cmd_blk.call(docker_db_repository, docker_db_container_name)
            end
            task :restart_ess, :roles => [:ess_app] do
              invoke_command start_docker_cmd_blk.call(docker_repository, docker_container_name)
            end
          end
        end
        
        namespace :deploy do
          desc <<-DESC
            cap deploy部署你的应用程序.
          DESC
          task :default do
            # restart docker container
            logger.trace "* docker executing: restart"
            
            # dynamic create aliyun role with ess hosts
            if aliyun_ess_name.present?
              ess = Webistrano::Aliyun::Ess.new(aliyun_ess_name, :access_key_id => aliyun_access_key_id, :secret_access_key => aliyun_secret_access_key)
              ips = ess.public_ips
              app_hosts = roles[:app] ? roles[:app].servers.map(&:host) : []
              db_hosts  = roles[:db]  ? roles[:db].servers.map(&:host)  : []
              ips = ips - app_hosts - db_hosts
              roles[:ess_app].push *ips, { :user => user }
              logger.trace "ESS: #{aliyun_ess_name}, instances: #{ips}"
            end
            
            webistrano.docker.restart
          end
        end
      EOS
    end
  end
end