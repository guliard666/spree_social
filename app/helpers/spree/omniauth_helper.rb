module Spree
  module OmniauthHelper
    def path_for_omniauth(user, provider)
      omniauth_authorize_path(user, provider)
    end
  end
end
