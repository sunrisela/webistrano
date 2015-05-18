# ess = Webistrano::Aliyun::Ess.new('rca.ad.ess')
# ess.public_ips
# ["121.40.218.10", "120.55.101.150", "121.41.116.248", "121.40.83.116"] 

module Webistrano
    module Aliyun
        class Ess
            def initialize(name)
                # 配置ESS SDK初始化
                ::Aliyun::ESS::Base.establish_connection!({
                    :access_key_id => ENV['ALIYUNACCESSKEYID'],
                    :secret_access_key => ENV['ALIYUNACCESSKEYSECRET']
                })
                group = self.fetch_scaling_group_by_name(name)
                # 伸缩组ID
                id = group.scaling_group_id
                @ecs = ::Aliyun::Deploy::EcsApi.new
                @ess = ::Aliyun::Deploy::EssApi.new(id)
            end

            # 得到该伸缩组下面，目前启动的服务器全部实例
            def instances
                # 得到该伸缩组下面的实例ID
                @_instances || instances!
            end

            def instances!
                # 得到该伸缩组下面的实例ID
                @_instances = []
                @ess.fetch_all_instances{ |id|  
                    @_instances << @ecs.query(id)
                }
                @_instances
            end

            # 得到该伸缩组下面，目前启动的服务器全部公网IP
            def public_ips
                self.instances.map { |e| e.public_ip_address }
            end

            # 根据伸缩组名称查找伸缩组实例:'rca.ad.ess'
            def fetch_scaling_group_by_name(name)
                ::Aliyun::ESS::ScalingGroup.find_by('scaling_group_name.1' => name)
            end
        end
    end
end