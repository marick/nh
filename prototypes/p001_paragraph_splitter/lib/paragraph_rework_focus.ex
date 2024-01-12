defmodule ParagraphReworkFocus do
  use GenServer
  require Logger


  @impl true
  def init(paragraph) do
    Logger.info("is watching now")
    {:ok, %{paragraph: paragraph}}
  end

  @impl true
  def handle_cast({:added,_grapheme}, state) do
    {:reply, :ok, state}
  end
end
