module MinaUtils
  class InstallGenerator < Rails::Generators::Base
    def create_deploy_config
      case self.behavior
      when :invoke
        name = ask("项目名称:")
        domain = ask("服务器域名/网址:")
        repository = ask("版本库地址:")
        branch = ask("版本库分支(默认为master):")
        create_file "config/deploy.rb",
          MinaUtil::Builder.deploy_config(name ,domain, repository, branch)
      when :revoke
        create_file "config/deploy.rb", ""
      end
    end

    def create_unicorn_config
      create_file "config/unicorn.rb", <<-FILE
worker_processes 3
preload_app true
timeout 60

app_path = File.expand_path("../../", __FILE__)

listen "\#{app_path}/tmp/sockets/unicorn.sock", :backlog => 2048
pid "\#{app_path}/tmp/pids/unicorn.pid"

stderr_path("\#{app_path}/log/unicorn-error.log")
stdout_path("\#{app_path}/log/unicorn.log")
      FILE
    end

    def create_deploy_sh
      case self.behavior
      when :invoke
      create_file "deploy/sh/function.sh", <<-FILE
#! /usr/bin/env bash

. /etc/profile

function assert_process_from_name_not_exist()
{
  local pid
  pid=$(ps aux|grep $1|grep -v grep|awk '{print $2}')
  if [ "$pid" ];then
  echo "已经有一个 $1 进程在运行"
  exit 5
  fi
}

function assert_process_from_pid_file_not_exist()
{
  local pid;

  if [ -f $1 ]; then
    pid=$(cat $1)
    if [ $pid ] && [ "$(ps $pid|grep -v PID)" ]; then
      echo "$1 pid_file 中记录的 pid 还在运行"
      exit 5
    fi
  fi
}

function check_run_status_from_pid_file()
{
  local pid;
  local service_name;
  service_name=$2
  if [ -f $1 ]; then
    pid=$(cat $1)
  fi

  if [ $pid ] && [ "$(ps $pid|grep -v PID)" ]; then
    echo -e "$service_name  [\\e[1;32mrunning\\e[0m]"
  else
    echo -e "$service_name  [\\e[1;31mnot running\\e[0m]"
  fi
}

function get_sh_dir_path()
{
  echo -n $(cd "$(dirname "$0")"; pwd)
}

function command_status()
{
  if [ $? == 0 ];then
    echo -e "[\\e[1;32msuccess\\e[0m]"
  else
    echo -e "[\\e[1;31mfail\\e[0m]"
  fi
}

      FILE

      create_file "deploy/sh/unicorn.sh", <<-FILE
#! /usr/bin/env bash

current_path=`cd "$(dirname "$0")"; pwd`
app_path=$current_path/../..

source /etc/profile
source $current_path/function.sh

pid=$app_path/tmp/pids/unicorn.pid

cd $app_path
echo "######### info #############"
echo "pid_file_path $pid"
echo "app_path $(pwd)"
echo "############################"

case "$1" in
  start)
    assert_process_from_pid_file_not_exist $pid
    bundle exec unicorn -c config/unicorn.rb -E production -D
    echo "app start .............$(command_status)"
  ;;
  status)
    check_run_status_from_pid_file $pid 'app'
  ;;
  stop)
    kill `cat $pid`
    echo "app stop .............$(command_status)"
  ;;
  usr2_stop)
    echo "usr2_stop"
    kill -USR2 `cat $pid`
    command_status
  ;;
  *)
    echo "tip:(start|stop|usr2_stop|status)"
    exit 5
  ;;
esac

exit 0
      FILE

      # TODO 设置权限
      when :revoke
        create_file "deploy/sh/function.sh", ""
        create_file "deploy/sh/unicorn.sh", ""
      end
    end

    # FIXME 应该写在config/deploy.rb里面
    def config_mongoid
      case self.behavior
      when :invoke
      p "=====mongoid配置===="
      database = ask "mongoid database:"
      host = ask "mongoid host(默认为localhost):"
      port = ask "mongoid port(默认为27017):"
      p MinaUtil::Builder.mongoid database, host, port
      p "=====mongoid配置结束===="
      when :revoke
        #create_file "config/mongoid.yml", ""
      end
    end
  end
end
