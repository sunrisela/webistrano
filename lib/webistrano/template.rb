require "webistrano/template/base"
require "webistrano/template/rails"
require "webistrano/template/mongrel_rails"
require "webistrano/template/thin_rails"
require "webistrano/template/pure_file"
require "webistrano/template/mod_rails"
require "webistrano/template/unicorn_rails"
require "webistrano/template/rainbows_rails"
require "webistrano/template/rainbows_rails_docker"

#Dir[File.expand_path("../template/*.rb", __FILE__)].each {|file| require file }
