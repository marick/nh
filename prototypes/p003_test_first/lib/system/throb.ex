alias AppAnimal.System.Throb

defmodule Throb do

  def default_rate(), do: 100

  def never(), do: seconds(1_000_000)

  def seconds(n) do
    trunc(n * 1000)
  end
end
