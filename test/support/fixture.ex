defmodule GalerieTest.Support.Fixture do
  alias GalerieTest.Support.Factory
  alias GalerieTest.Support.MockConfig

  def create_user(context) do
    user_params = Map.get(context, :user_params, [])
    [user: Factory.insert!(:user, user_params)]
  end

  def enforce_password_rules(context) do
    enforce_rules = Map.get(context, :enforce_rules, true)
    MockConfig.mock_config(:galerie, Galerie.Accounts.User.Password, enforce_rules: enforce_rules)
    :ok
  end
end
