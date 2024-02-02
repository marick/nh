defmodule AppAnimal.Pretty.Cursor do
  def pretty(%{text: text, cursor: cursor}) do
    {prefix, suffix} = String.split_at(text, cursor)
    ~s/"#{single_line(prefix)}\u2609\u2609#{single_line(suffix)}"/
  end

  defp single_line(string) do
    String.replace(string, "\n", "\\n")
  end
end
