defmodule AppAnimal do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    state = %{text: "", cursor: 0}
    {:ok, state}
  end

  @impl true
  def handle_call({:focus_on_paragraph, text, cursor}, _from, _state) do
    starting_state = %{text: text, cursor: cursor}
    Logger.info("focused on #{inspect starting_state}")
    GenServer.start_link(ParagraphFocus, starting_state, name: :current_paragraph_focus)
    {:reply, :ok, :ok}
  end


end
