defmodule AppAnimal do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    paragraph_state = %{text: "___", cursor: 1}
    {:ok, paragraph} =
      GenServer.start(Paragraph, paragraph_state)
    
    {:ok, _focus} = GenServer.start_link(Paragraph.Focus, paragraph)

    add(paragraph, "Q")
    add(paragraph, "\n")
    add(paragraph, "\n")
    add(paragraph, "A")
    {:ok, self()}
  end

  @how :call

  def add(paragraph, grapheme), 
    do: apply(GenServer, @how, [paragraph, {:add, grapheme}])
end
