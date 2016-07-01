module MinaUtil
  class Routing
    # MinaUtil::Routing.mount "/mina_util", :as => 'mina_util'
    def self.mount(prefix, options)
      MinaUtil.set_mount_prefix prefix

      Rails.application.routes.draw do
        mount MinaUtil::Engine => prefix, :as => options[:as]
      end
    end
  end
end
