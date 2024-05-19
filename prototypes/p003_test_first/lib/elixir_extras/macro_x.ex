defmodule AppAnimal.MacroX do
  def put_expansion(ast) do
    Macro.expand_once(ast, __ENV__) |> Macro.to_string |> IO.puts
  end
end
