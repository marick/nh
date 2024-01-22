defmodule AppAnimal.ParagraphFocus.Control.Util do
  def text_count(edges) do
    edges |> Keyword.keys |> Enum.count(&(&1 == :text))
  end
end
