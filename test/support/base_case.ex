defmodule Galerie.BaseCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias GalerieTest.Support.MockConfig
      import GalerieTest.Support.Fixture
    end
  end
end
