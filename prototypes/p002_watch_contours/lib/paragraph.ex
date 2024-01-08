defmodule Paragraph do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts)
  end


  @impl true
  def init(initial_state) do
    log_text(initial_state)
    {:ok, initial_state}
  end

  @impl true
  def handle_cast({:insert, string}, state) do
    {prefix, suffix} = String.split_at(state.text, state.cursor)
    new_state = %{state |
                  text: prefix <> string <> suffix,
                  cursor: state.cursor + String.length(string)}
                  
    log_text(new_state)
    {:noreply, new_state}
  end

  @impl true
  def handle_call(:text, _from, state), do: {:reply, state.text, state}
  @impl true
  def handle_call(:cursor, _from, state), do: {:reply, state.cursor, state}

  
  # @impl true
  # def init(%{text: text, cursor: cursor}) do
  #   state = %{text: text, cursor: cursor}
  #   "starts with #{visible_cursor(state)}" |> Logger.info
  #   {:ok, state}
  # end

  def log_text(state), do: ["has ", visible_cursor(state)] |> Logger.info

  def visible_cursor(%{text: text, cursor: cursor}) do
    {prefix, suffix} = String.split_at(text, cursor)
    "'#{prefix}\u2609\u2609#{suffix}'"
  end
end
