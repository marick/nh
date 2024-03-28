alias AppAnimal.Duration

defmodule Duration do
  def quantum(), do: 100 # milliseconds
  def quanta(n), do: n * quantum()

  @doc "Used in tests that want to control throbbing themselves"
  def foreverish(), do: seconds(10_000_000)   # four months

  def frequent_glance, do: seconds(2)

  def seconds(n), do: trunc(n * 1000)
end


