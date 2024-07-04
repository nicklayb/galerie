defmodule NectarineTest.Support.Mocks.MockGenerator do
  @behaviour Nectarine.Generator

  @impl Nectarine.Generator
  def generate(options) do
    case Keyword.fetch!(options, :value) do
      sequence when is_list(sequence) ->
        next_item(sequence)

      value ->
        value
    end
  end

  defp next_item(sequence) do
    current_index = Process.get(:generator_sequence, 0)

    sequence
    |> Enum.at(current_index)
    |> tap(fn _ -> Process.put(:generator_sequence, current_index + 1) end)
  end
end
