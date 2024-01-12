defmodule AppAnimal do
  use Application
  require Logger

  @impl true
  def start(_type, args) do
    Logger.info("one")
    {:ok, focus} = GenServer.start_link(Paragraph.Focus, :ok, args)
    Logger.info("two")
    GenServer.call(focus, {:focus_on_paragraph, "abc", 1})
    GenServer.call(:current_paragraph, {:add, "!"})
    GenServer.call(:current_paragraph, {:add, "\n"})
    GenServer.call(:current_paragraph, {:add, "\n"})
    {:ok, focus}
  end
  
end
