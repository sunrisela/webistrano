#source 'http://rubygems.org'
source 'https://gems.ruby-china.org'

gem 'rails', '3.2.21'

gem 'jquery-rails', '~> 2.1.4'

gem 'capistrano', '2.15.5'
gem 'open4',      '~> 1.3.4'
gem 'syntax',     '~> 1.2.0'
gem 'version_fu'
gem 'devise'
gem 'haml'

gem 'byebug', group: [:development, :test]

gem 'sqlite3-ruby', group: [:development, :test]
gem 'mysql2', group: [:production]
# 索引检查工具
gem 'lol_dba', group: [:development]

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.6'
  gem 'coffee-rails', '~> 3.2.2'

  gem 'compass-rails'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'test-unit', '~> 2.0', :require => 'test/unit'
  gem 'mocha'
  gem 'factory_girl_rails'
end

# Use unicorn as the app server
gem 'unicorn'

# deploy
gem 'rvm-capistrano', :require => false
gem 'whenever', :require => false

# 阿里云服务SDK
gem 'aliyun_ruby_api', github: 'charlescui/aliyun_ruby_api'
gem 'aliyun-ess', '~> 0.1.7'
