defmodule Paragraph.Focus do
  use GenServer
  require Logger

  @impl true
  def init(paragraph) do
    Logger.info("is watching paragraph")
    {:ok, focus} =
      GenServer.start(AboutBigEdit, paragraph)
    GenServer.call(paragraph, {:observer, focus})
    {:ok, paragraph}
  end
end
