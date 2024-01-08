defmodule Paragraph do
  use GenServer
  require Logger


  @impl true
  def init(%{text: text, cursor: cursor}) do
    state = %{text: text, cursor: cursor}
    "starts with #{visible_cursor(state)}" |> Logger.info
    {:ok, state}
  end

  @impl true
  def handle_call({:observer, observer}, _from, state) do
    {:reply, :ok, Map.put(state, :observer, observer)}
  end

  @impl true
  def handle_call({:add, grapheme}, _from, state) do
    "is adding #{grapheme}" |> Logger.info
    
    {prefix, suffix} = String.split_at(state.text, state.cursor)
    next_text = prefix <> grapheme <> suffix
    next_cursor = state.cursor + 1
    next_state = %{state | text: next_text, cursor: next_cursor}
    GenServer.call(state.observer, {:added, grapheme})

    Logger.info(visible_cursor(next_state))
    {:reply, :ok, next_state}
  end

  def visible_cursor(%{text: text, cursor: cursor}) do
    {prefix, suffix} = String.split_at(text, cursor)
    "'#{prefix}\u2609\u2609#{suffix}'"
  end
end
