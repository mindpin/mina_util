Rails.application.routes.draw do
  MinaUtil::Routing.mount '/', :as => 'mina_util'
  mount PlayAuth::Engine => '/auth', :as => :auth
  root to: "home#index"
end
