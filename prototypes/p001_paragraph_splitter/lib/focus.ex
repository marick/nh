defmodule Paragraph.Focus do
  use GenServer
  require Logger

  @impl true
  def init(paragraph) do
    {:ok, focus} =
      GenServer.start(About.BigEdit, paragraph)
    GenServer.call(paragraph, {:observer, focus})
    {:ok, paragraph}
  end
end
