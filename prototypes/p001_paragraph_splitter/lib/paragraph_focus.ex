defmodule ParagraphFocus do
  use GenServer
  require Logger


  @impl true
  def init(paragraph) do
    {:ok, %{paragraph: paragraph, last_grapheme: ""}}
  end

  @impl true
  def handle_call({:added, grapheme}, _from, state) do
    Logger.info("notices #{grapheme}")
    if state.last_grapheme == "\n" && grapheme == "\n" do
      {:ok, focus} =
        GenServer.start_link(ParagraphReworkFocus, state.paragraph)
      GenServer.call(state.paragraph, {:observer, focus})
      {:stop, :normal, :ok, state}
    end
    {:reply, :ok, %{state | last_grapheme: grapheme}}
  end

end
