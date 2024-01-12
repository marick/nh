defmodule AppAnimal do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    paragraph_state = %{text: "abc", cursor: 1}
    {:ok, paragraph} =
      GenServer.start(Paragraph, paragraph_state)
    
    {:ok, _focus} = GenServer.start_link(Paragraph.Focus, paragraph)
    
    GenServer.call(paragraph, {:add, "!"})
    GenServer.call(paragraph, {:add, "\n"})
    GenServer.call(paragraph, {:add, "\n"})

    GenServer.call(paragraph, {:add, "AAAAAA"})
    {:ok, self()}
  end
end
