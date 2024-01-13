defmodule About.BigEdit do
  use GenServer
  require Logger


  @impl true
  def init(paragraph) do
    Logger.info("is watching now")
    {:ok, %{paragraph: paragraph, last_grapheme: ""}}
  end

  @impl true
  def handle_cast({:added, grapheme}, state) do
    Logger.info("is alerted to the new grapheme #{inspect grapheme}")
    if state.last_grapheme == "\n" && grapheme == "\n" do
      {:ok, focus} =
        GenServer.start(About.Fragments, state.paragraph)
      GenServer.call(state.paragraph, {:observer, focus})
      {:stop, :normal, :ok, state}
    end
    {:noreply, %{state | last_grapheme: grapheme}}
  end

end
