defmodule AppAnimal.PrettyModule do
  def terse(arg) when is_atom(arg) do
    inspect(arg)
    |> String.split(".")
    |> Enum.slice(-2..-1)
    |> Enum.join(".")
  end

  def minimal(arg) when is_atom(arg) do
    inspect(arg)
    |> String.split(".")
    |> List.last
  end
end
