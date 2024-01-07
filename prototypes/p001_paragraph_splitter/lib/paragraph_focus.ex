defmodule ParagraphFocus do
  use GenServer
  require Logger


  @impl true
  def init(starting_state) do
    Logger.info(starting_state)
    {:ok, starting_state}
  end

  @impl true
  def handle_call(:ping, _from, state) do
    Logger.info("pong")
    {:reply, :ok, state}
  end
  
end
