defmodule AppAnimal.Extras.Tuples do
  def ok(value), do: {:ok, value}
  def okval({:ok, value}), do: value
end
