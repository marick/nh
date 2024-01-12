defmodule Paragraph.Focus do
  use GenServer
  require Logger

  @impl true
  def init(paragraph) do
    {:ok, focus} =
      GenServer.start(AboutBigEdit, paragraph)
    GenServer.call(:current_paragraph, {:observer, focus})
    {:ok, paragraph}
  end
end
