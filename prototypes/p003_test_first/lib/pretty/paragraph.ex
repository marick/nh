alias AppAnimal.Pretty

defmodule Pretty.Paragraph do
  def lines(%{text: text, cursor: cursor}) do
    {prefix, suffix} = String.split_at(text, cursor)
    ~s/"#{single_line(prefix)}\u2609\u2609#{single_line(suffix)}"/ #  ■_■_■ and such
  end

  defp single_line(string) do
    String.replace(string, "\n", "\\n")
  end
end
