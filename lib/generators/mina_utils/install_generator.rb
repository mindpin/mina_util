module MinaUtils
  class InstallGenerator < Rails::Generators::Base
    source_root File.expand_path('../templates', __FILE__)

    def create_deploy_config
      case self.behavior
      when :invoke
        name = ask("项目名称:")
        domain = ask("服务器域名/IP:")
        user = ask("服务器用户(默认为root):")
        repository = ask("版本库地址:")
        branch = ask("版本库分支(默认为master):")
        create_file "config/deploy.rb",
          MinaUtil::Builder.deploy_config(name ,domain, repository, branch, user)
      when :revoke
        create_file "config/deploy.rb", ""
      end
    end

    def create_unicorn_config
      copy_file "unicorn.rb", "config/unicorn.rb"
    end

    def create_deploy_sh
      copy_file "function.sh", "deploy/sh/function.sh", mode: :preserve
      copy_file "unicorn.sh", "deploy/sh/unicorn.sh", mode: :preserve
    end

  end
end
