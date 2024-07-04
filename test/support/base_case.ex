defmodule Nectarine.BaseCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias NectarineTest.Support.MockConfig
      import NectarineTest.Support.Fixture
    end
  end
end
