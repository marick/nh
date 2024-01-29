defmodule AppAnimal.ParagraphFocus.Environment do 
  use GenServer
  require Logger

  def activate(paragraph_state) do
    {:ok, _pid} = start_link(paragraph_state)
  end

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
  def handle_call({:run_for_result, f}, _from, paragraph_state) do
    result = f.(paragraph_state.text)
    {:reply, result, paragraph_state}
  end

  @impl true
  def handle_cast({:apply_to_self, f}, paragraph_state) do
    {:noreply, f.(paragraph_state)}
  end

  def log_text(state) do
    Logger.info("has #{visible_cursor(state)}", newlines: :visible)
  end

  def visible_cursor(%{text: text, cursor: cursor}) do
    {prefix, suffix} = String.split_at(text, cursor)
    "'#{prefix}\u2609\u2609#{suffix}'"
  end
end
