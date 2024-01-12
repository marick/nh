defmodule AboutFragments do
  use GenServer
  require Logger


  @impl true
  def init(paragraph) do
    Logger.info("is watching now")
    {:ok, %{paragraph: paragraph}}
  end

  @impl true
  def handle_cast({:added,grapheme}, state) do
    Logger.info("sees #{inspect grapheme}")
    {:reply, :ok, state}
  end
end
