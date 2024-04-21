defmodule AppAnimal.Extras.Kernel do
  use Private

  def constantly(value), do: fn _ -> value end

  @doc "Sometimes `pi(tag: value)` fits better than `IO.inspect` or `dbg`."
  def pi([{tag, value}]), do: IO.puts "#{tag}: #{inspect value}"

  defmacro precondition(expression) do
    quote do
      unless unquote(expression) do
        dbg {"Precondition failure", unquote(expression)}
        raise("Precondition failure")
      end
    end
  end
end
