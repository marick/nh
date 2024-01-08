defmodule Paragraph do
  use GenServer
  require Logger


  @impl true
  def init(%{text: text, cursor: cursor}) do
    state = %{graphemes: String.graphemes(text), cursor: cursor}
    Logger.info(state)
    {:ok, state}
  end

  @impl true
  def handle_call({:observer, observer}, _from, state) do
    
    {:reply, :ok, Map.put(state, :observer, observer)}
  end


  @impl true
  def handle_call({:add, grapheme}, _from, state) do
    Logger.info("adding #{grapheme} to #{inspect state}")
    next_graphemes = List.insert_at(state.graphemes, state.cursor, grapheme)
    next_cursor = state.cursor + 1
    next_state = %{state | graphemes: next_graphemes, cursor: next_cursor}
    GenServer.call(state.observer, {:added, grapheme})
    Logger.info(inspect next_state)
    {:reply, :ok, next_state}
  end
  
  
  
end
