defmodule ParagraphReworkFocus do
  use GenServer
  require Logger


  @impl true
  def init(paragraph) do
    Logger.info(inspect paragraph)
    {:ok, %{paragraph: paragraph}}
  end

  @impl true
  def handle_call({:added, _grapheme}, _from, state) do
    {:reply, :ok, state}
  end
end
