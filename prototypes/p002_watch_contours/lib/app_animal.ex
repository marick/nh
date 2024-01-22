defmodule AppAnimal do
  use Application
  alias AppAnimal.{ParagraphFocus}
  require Logger


  @impl true
  def start(_type, _args) do
    paragraph_state = %{text: "___", cursor: 1}
    {:ok, pid} = ParagraphFocus.start_link(paragraph_state)
    Logger.info("paragraph focus is #{inspect pid}")
    
    # {:ok, _focus} = GenServer.start_link(Paragraph.Focus, paragraph)

    # # add(paragraph, "Q")
    # # add(paragraph, "\n")
    # # add(paragraph, "\n")
    # # add(paragraph, "A")
    {:ok, self()}
  end

  # def add(paragraph, grapheme),
  #     do: GenServer.cast(paragraph, {:add, grapheme})

end
