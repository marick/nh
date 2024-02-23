defmodule AppAnimal.ParagraphFocus.Environment do 
  use GenServer
  require Logger
  alias AppAnimal.Pretty

  def start_link(paragraph_state) do
    GenServer.start_link(__MODULE__, paragraph_state, name: __MODULE__)
  end

  # Server

  @impl true
  def init(initial_state) do
    log_text(initial_state)
    {:ok, initial_state}
  end

  @impl true
  def handle_call([summarize_with: f], _from, paragraph_state) do
    result = f.(paragraph_state.text)
    {:reply, result, paragraph_state}
  end

  @impl true
  def handle_cast([update_with: f], paragraph_state) do
    {:noreply, f.(paragraph_state)}
  end

  def log_text(state) do
    Logger.info("has #{Pretty.Paragraph.lines(state)}", newlines: :visible)
  end
end
