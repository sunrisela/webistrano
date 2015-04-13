# TODO - is this needed? -- fd
require 'open4'
require 'capistrano/cli'
require 'syntax/convertors/html'

require "#{Rails.root}/config/webistrano_config"

# set default time_zone to UTC
# TODO - is this needed? -- fd
#ENV['TZ'] = 'UTC'
#Time.zone = 'UTC'