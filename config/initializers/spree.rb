Rails.application.config.after_initialize do
  authentication_methods_item = Spree::Admin::MainMenu::ItemBuilder.new('social_authentication_methods', Spree::Core::Engine.routes.url_helpers.admin_authentication_methods_path).with_manage_ability_check(Spree::AuthenticationMethod).with_match_path('/authentication_methods').build

  menu = Rails.application.config.spree_backend.main_menu
  integrations_submenu = menu.items.select{|e| e.key == "integrations"}.first
  integrations_submenu.add(authentication_methods_item)
end