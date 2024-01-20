defmodule Paragraph.Focus do
  use GenServer
  require Logger

  @impl true
  def init(paragraph) do
    will_watch_for_edges()
    {:ok, paragraph}
  end

  @impl true
  def handle_info(:check_edges, state) do
    Logger.info("tick")
    will_watch_for_edges()
    {:noreply, state}
  end


  def will_watch_for_edges() do
    Process.send_after(self(), :check_edges, 2_000)
  end
end
