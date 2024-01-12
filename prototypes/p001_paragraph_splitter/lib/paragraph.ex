defmodule Paragraph do
  use GenServer
  require Logger
  alias AppAnimal.Cursor


  @impl true
  def init(%{text: text, cursor: cursor}) do
    state = %{text: text, cursor: cursor}
    "starts with #{Cursor.pretty(state)}" |> Logger.info
    {:ok, state}
  end

  @impl true
  def handle_call({:observer, observer}, _from, state) do
    {:reply, :ok, Map.put(state, :observer, observer)}
  end

  @impl true
  def handle_call({:add, grapheme}, _from, state) do
    "is adding #{inspect grapheme}" |> Logger.info
    
    {prefix, suffix} = String.split_at(state.text, state.cursor)
    next_text = prefix <> grapheme <> suffix
    next_cursor = state.cursor + 1
    next_state = %{state | text: next_text, cursor: next_cursor}
    GenServer.cast(state.observer, {:added, grapheme})

    Logger.info("has been modified into #{Cursor.pretty(next_state)}")
    {:reply, :ok, next_state}
  end
end
