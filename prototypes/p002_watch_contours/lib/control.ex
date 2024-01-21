defmodule Control do
  use Private

  private do 
    def editing?(edges) do
      text_count(edges) > 1
    end


    def text_count(edges) do
      edges |> Keyword.keys |> Enum.count(&(&1 == :text))
    end
  end
    
end
