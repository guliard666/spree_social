class Spree::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  include Spree::Core::ControllerHelpers::Common
  include Spree::Core::ControllerHelpers::Order
  include Spree::Core::ControllerHelpers::Auth
  include Spree::Core::ControllerHelpers::Store
  if defined?(Spree::Core::ControllerHelpers::Currency)
    include Spree::Core::ControllerHelpers::Currency
  end

  def self.provides_callback_for(*providers)
    providers.each do |provider|
      class_eval <<-FUNCTION_DEFS, __FILE__, __LINE__ + 1
        def #{provider}
          if request.env['omniauth.error'].present?
            flash[:error] = I18n.t('devise.omniauth_callbacks.failure', kind: auth_hash['provider'].to_s.split('_').first.titleize, reason: Spree.t(:user_was_not_valid))
            redirect_back_or_default(root_url)
            return
          end

          authentication = Spree::UserAuthentication.find_by_provider_and_uid(auth_hash['provider'], auth_hash['uid'])

          if authentication.present? and authentication.try(:user).present?
            flash[:notice] = I18n.t('devise.omniauth_callbacks.success', kind: auth_hash['provider'].to_s.split('_').first.titleize)
            sign_in_and_redirect :spree_user, authentication.user
          elsif spree_current_user
            spree_current_user.apply_omniauth(auth_hash)
            if auth_hash && auth_hash['info']['name'].present?
              name_arr = auth_hash['info']['name'].to_s.split(" ")
              spree_current_user.first_name = name_arr[0] if spree_current_user.first_name.nil?
              spree_current_user.last_name = name_arr[1] if spree_current_user.last_name.nil?
            end
            if spree_current_user.confirmed_at.nil?
              spree_current_user.confirmation_sent_at = Time.now
              spree_current_user.confirmed_at = Time.now
              spree_current_user.confirmation_token = Devise.friendly_token
            end
            spree_current_user.save!
            flash[:notice] = I18n.t('devise.sessions.signed_in')
            redirect_back_or_default(account_url)
          else
            user = Spree::User.find_by_email(auth_hash['info']['email']) || Spree::User.new
            user.apply_omniauth(auth_hash)
            if auth_hash && auth_hash['info']['name'].present?
              name_arr = auth_hash['info']['name'].to_s.split(" ")
              user.first_name = name_arr[0] if user.first_name.nil?
              user.last_name = name_arr[1] if user.last_name.nil?
            end
            if user.confirmed_at.nil?
              user.confirmation_sent_at = Time.now
              user.confirmed_at = Time.now
              user.confirmation_token = Devise.friendly_token
            end
            if user.save
              flash[:notice] = I18n.t('devise.omniauth_callbacks.success', kind: auth_hash['provider'].to_s.split('_').first.titleize)
              sign_in_and_redirect :spree_user, user
            else
              session[:omniauth] = auth_hash.except('extra')
              flash[:notice] = Spree.t(:one_more_step, kind: auth_hash['provider'].to_s.split('_').first.titleize)
              redirect_to new_spree_user_registration_url
              return
            end
          end

          if current_order
            user = spree_current_user || authentication.user
            current_order.associate_user!(user)
            session[:guest_token] = nil
          end
        end
      FUNCTION_DEFS
    end
  end

  SpreeSocial::OAUTH_PROVIDERS.each do |provider|
    provides_callback_for provider[1].to_sym
  end

  def failure
    set_flash_message :alert, :failure, kind: failed_strategy.name.to_s.humanize, reason: failure_message
    redirect_to spree.login_path
  end

  def passthru
    render file: "#{Rails.root}/public/404", formats: [:html], status: 404, layout: false
  end

  def auth_hash
    request.env['omniauth.auth']
  end
end
