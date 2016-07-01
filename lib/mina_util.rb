require 'rails/generators'
require 'generators/mina_utils/install_generator'

module MinaUtil
  class << self
    def mina_util_config
      self.instance_variable_get(:@mina_util_config) || {}
    end

    def set_mount_prefix(mount_prefix)
      config = MinaUtil.mina_util_config
      config[:mount_prefix] = mount_prefix
      MinaUtil.instance_variable_set(:@mina_util_config, config)
    end

    def get_mount_prefix
      mina_util_config[:mount_prefix]
    end
  end
end

# 引用 rails engine
require 'mina_util/engine'
require 'mina_util/rails_routes'
