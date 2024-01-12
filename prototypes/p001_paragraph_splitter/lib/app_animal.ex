defmodule AppAnimal do
  use Application
  require Logger

  @impl true
  def start(_type, _args) do
    paragraph_state = %{text: "abc", cursor: 1}
    {:ok, paragraph} =
      GenServer.start(Paragraph, paragraph_state, name: :current_paragraph)
    
    {:ok, _focus} = GenServer.start_link(Paragraph.Focus, paragraph)
    
    GenServer.call(:current_paragraph, {:add, "!"})
    GenServer.call(:current_paragraph, {:add, "\n"})
    GenServer.call(:current_paragraph, {:add, "\n"})
    {:ok, self()}
  end
  
end
