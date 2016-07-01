module MinaUtil
  class Engine < ::Rails::Engine
    isolate_namespace MinaUtil
    config.to_prepare do
      ApplicationController.helper ::ApplicationHelper

      Dir.glob(Rails.root + "app/decorators/mina_util/**/*_decorator.rb").each do |c|
        require_dependency(c)
      end
    end
  end
end
