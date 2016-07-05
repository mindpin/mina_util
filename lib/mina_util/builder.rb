module MinaUtil
  class Builder
    cattr_accessor :project_name

    def self.deploy_config name, domain, repository, branch, user, project_path#, nginx_name
      branch = "master" if branch.blank?
      user = "master" if user.blank?
      project_path = "/web/#{name}" if project_path.blank?
      <<-FILE
require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'rails/generators'
require 'mina_util/builder'
require 'yaml'

set :domain, '#{domain}'
set :deploy_to, '#{project_path}'
#test
#set :deploy_to, '/home/dd/#{name}'
set :current_path, 'current'
set :repository, '#{repository}'
set :branch, '#{branch}'
set :user, '#{user}'
set :term_mode, nil

set :shared_paths, [
  'config/mongoid.yml',
  'config/secrets.yml',
  'config/application.yml',
  'tmp',
  'log'
]

task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
end

task :setup => :environment do
  queue! %[mkdir -p "\#{deploy_to}/shared/tmp/sockets"]
  queue! %[chmod g+rx,u+rwx "\#{deploy_to}/shared/tmp/sockets"]

  queue! %[mkdir -p "\#{deploy_to}/shared/tmp/pids"]
  queue! %[chmod g+rx,u+rwx "\#{deploy_to}/shared/tmp/pids"]

  queue! %[mkdir -p "\#{deploy_to}/shared/tmp/logs"]
  queue! %[chmod g+rx,u+rwx "\#{deploy_to}/shared/tmp/logs"]

  queue! %[mkdir -p "\#{deploy_to}/shared/config"]
  queue! %[chmod g+rx,u+rwx "\#{deploy_to}/shared/config"]

  #queue! %[touch "\#{deploy_to}/shared/config/mongoid.yml"]
  order = MinaUtil::Builder.ask_mongoid
  queue! %[echo '\#{order}' > "\#{deploy_to}/shared/config/mongoid.yml"]

  secrets = MinaUtil::Builder.ask_secrets
  queue! %[echo '\#{secrets}' > "\#{deploy_to}/shared/config/secrets.yml"]

  nginx = MinaUtil::Builder.ask_nginx('#{name}')
  queue! %[echo '\#{nginx}' > "/etc/nginx/conf.d/#{name}.conf"]
  #test
  #queue! %[echo '\#{nginx}' > "/home/dd/#{name}.conf"]

  queue! %[touch "\#{deploy_to}/shared/config/application.yml"]
  if File.exist? "config/application.yml.sample"
    figaro = MinaUtil::Builder.ask_figaro
    queue! %[echo '\#{figaro}' > "\#{deploy_to}/shared/config/application.yml"]
  else
    # 不处理
    queue  %[echo "未在本地发现 'config/application.yml.sample'."]
    queue  %[echo "略过figaro配置."]
  end

  queue! %[mkdir -p "\#{deploy_to}/shared/log"]
  queue! %[chmod g+rx,u+rwx "\#{deploy_to}/shared/log"]
end

desc "Deploys the current version to the server."
task :deploy => :environment do
  to :before_hook do
    # Put things to run locally before ssh
  end
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    to :launch do
      queue %[
        source /etc/profile
        bundle
        RAILS_ENV="production" bundle exec rake assets:precompile
        ./deploy/sh/unicorn.sh stop
        ./deploy/sh/unicorn.sh start
      ]
    end
  end

end

desc "update code only"
task :update_code => :environment do
  deploy do
    invoke :'git:clone'
    invoke :'deploy:link_shared_paths'
    to :launch do
      queue %[
        source /etc/profile
        bundle
        RAILS_ENV="production" bundle exec rake assets:precompile
      ]
    end
  end
end

desc "restart server"
task :restart => :environment do
  queue %[
    source /etc/profile
    cd \#{deploy_to}/\#{current_path}
    ./deploy/sh/unicorn.sh stop
    ./deploy/sh/unicorn.sh start
  ]
end
      FILE
    end

    def self.mongoid database, host, port
      host ="localhost" if host.blank?
      port = "27017" if port.blank?
      """
production:
  sessions:
    default:
      hosts:
        - #{host}:#{port}
      database: #{database}
      """
    end

    def self.ask_mongoid
      p "=====mongoid配置===="
      database = ask "mongoid database:"
      host = ask "mongoid host(默认为localhost):"
      port = ask "mongoid port(默认为27017):"
      mongoid database, host, port
    end

    def self.secrets secret
      secret = SecureRandom.hex(32) if secret.blank?
      """
production:
  secret_key_base: #{secret}
      """
    end

    def self.ask_secrets
      p "=====secrets配置===="
      secrets ask "secrets(默认自动生成):"
    end

    def self.nginx(name, server_name)
"""
upstream #{name}_server {
  server unix:/web/#{name}/current/tmp/sockets/unicorn.sock fail_timeout=0;
}

server {
    listen       80;
    server_name  #{server_name};
    root /web/#{name}/current/public;
    access_log  /var/log/nginx/#{name}.access.log  main;

    location / {
      try_files $uri @app;
    }

    location @app {
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
      proxy_set_header X-Real-IP $remote_addr;
      proxy_set_header X-Scheme $scheme;

      proxy_pass http://#{name}_server;
   }


}

"""
    end

    def self.ask_nginx(name)
      p "=====nginx配置===="
      server_name = ask "访问域名，例(xx.4ye.me):"
      nginx name, server_name
    end

    def self.ask_figaro
      p "=====figaro配置===="
      data = YAML::load(File.open("config/application.yml.sample"))
      envs = []
      envs << data.delete("test")
      envs << data.delete("development")
      envs << data.delete("production")
      envs.each do |e|
        data.merge! e unless e.nil?
      end

      output = ""
      data.each do |k, v|
        value = ask "#{k}(提示：#{v}):"
        output += "#{k}: #{value}\r\n"
      end
      output
    end

    protected
    def self.ask(statement, *args)
      options = args.last.is_a?(Hash) ? args.pop : {}
      color = args.first

      #if options[:limited_to]
        #ask_filtered(statement, color, options)
      #else
        ask_simply(statement, color, options)
      #end
    end


    def self.ask_simply(statement, color, options)
      default = options[:default]
      message = [statement, ("(#{default})" if default), nil].uniq.join(" ")
      message = prepare_message(message, *color)
      result = Thor::LineEditor.readline(message, options)

      return unless result

      result.strip!

      if default && result == ""
        default
      else
        result
      end
    end

    def self.prepare_message(message, *color)
      spaces = "  " * 0 #padding
      spaces + set_color(message.to_s, *color)
    end

    def self.set_color(string, *args) #:nodoc:
      string
    end

  end
end
