alias AppAnimal.Clock

defmodule Clock do
  def default_rate(), do: 100 # milliseconds

  @doc "Used in tests that want to control throbbing themselves"
  def impossibly_slowly(), do: seconds(1_000_000)

  def seconds(n), do: trunc(n * 1000)
end


