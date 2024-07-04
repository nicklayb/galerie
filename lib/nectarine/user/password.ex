defmodule Nectarine.User.Password do
  @moduledoc """
  Module to enforce password rules
  """
  require Logger

  @doc "Validates that a given field matches password rules"
  @spec validate(Ecto.Changeset.t(), atom()) :: Ecto.Changeset.t()
  def validate(%Ecto.Changeset{} = changeset, field \\ :password) do
    Nectarine.Changeset.update_valid(changeset, fn changeset ->
      case Ecto.Changeset.get_change(changeset, field) do
        nil -> changeset
        password -> validate_rules(changeset, password, field)
      end
    end)
  end

  @minimum_password_length 8
  @password_rules %{
    minimum_length: "must be at least #{@minimum_password_length} characters long",
    has_non_capitals: "must have non capitals",
    has_capitals: "must have capitals",
    has_numbers: "must have numbers"
  }
  @password_rule_keys Map.keys(@password_rules)
  defp validate_rules(changeset, password, field) do
    if enforces_password_rules?() do
      password
      |> validate_rules()
      |> Enum.reduce(
        changeset,
        &Ecto.Changeset.add_error(&2, field, Map.fetch!(@password_rules, &1))
      )
    else
      Logger.warning(
        "#{inspect(__MODULE__)}.matches_password_requirements enforce_password_rules=false"
      )

      changeset
    end
  end

  defp validate_rules(password) do
    Enum.reject(@password_rule_keys, &rule_matched?(password, &1))
  end

  defp rule_matched?(password, :minimum_length) do
    String.length(password) >= @minimum_password_length
  end

  defp rule_matched?(password, :has_non_capitals) do
    Regex.match?(~r/[a-z]/, password)
  end

  defp rule_matched?(password, :has_capitals) do
    Regex.match?(~r/[A-Z]/, password)
  end

  defp rule_matched?(password, :has_numbers) do
    Regex.match?(~r/[0-9]/, password)
  end

  defp enforces_password_rules? do
    Application.fetch_env!(:nectarine, Nectarine.User.Password)[:enforce_rules]
  end
end
