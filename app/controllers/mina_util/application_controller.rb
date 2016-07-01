module MinaUtil
  class ApplicationController < ActionController::Base
    layout "mina_util/application"

    if defined? PlayAuth
      helper PlayAuth::SessionsHelper
    end
  end
end