defmodule AppAnimal.ParagraphFocus do
  use GenServer
  require Logger

  alias AppAnimal.ParagraphFocus.{Environment, Perceptual}
  alias AppAnimal.Neural.Oscillator
  alias Perceptual.EdgeDetection
  require Logger
  
  # Client
  
  def start_link(paragraph_state) do
    GenServer.start_link(__MODULE__, paragraph_state)
  end
  
  # Server
  

  @impl true
  def init(paragraph_state) do
    Logger.info("focus on a new paragraph")
    Environment.activate(paragraph_state)
    
    {:ok, _task_starter} =
      Oscillator.poke(EdgeDetection, every: 5_000)
    {:ok, :ok}
  end
end
