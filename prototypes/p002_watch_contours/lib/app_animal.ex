defmodule AppAnimal do
  use GenServer
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    state = %{text: "", cursor: 0}
    {:ok, state}
  end

  @impl true
  def handle_call({:focus_on_paragraph, text, cursor}, _from, state) do
    paragraph_state = %{text: text, cursor: cursor}
    {:ok, _paragraph} =
      GenServer.start_link(Paragraph, paragraph_state, name: :current_paragraph)
    {:reply, self(), state}
  end
end
