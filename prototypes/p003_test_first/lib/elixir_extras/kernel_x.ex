defmodule AppAnimal.Extras.KernelX do
  @moduledoc "Some things I wish were in the Elixir `Kernel`."
  use Private

  @doc """
  Create a function that takes a single argument, ignores it, and always returns the
  given `value`.
  """
  def constantly(value), do: fn _ -> value end

  @doc "Sometimes `pi(tag: value)` fits better than `IO.inspect` or `dbg`."
  def pi([{tag, value}]), do: IO.puts "#{tag}: #{inspect value}"

  @doc "Raise an error if the precondition is false."
  defmacro precondition(expression) do
    quote do
      unless unquote(expression) do
        dbg {"Precondition failure", unquote(expression)}
        raise("Precondition failure")
      end
    end
  end
end
