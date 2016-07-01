class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  if defined? PlayAuth
    helper PlayAuth::SessionsHelper
  end
end

