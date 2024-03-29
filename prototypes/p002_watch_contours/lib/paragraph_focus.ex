defmodule AppAnimal.ParagraphFocus do
  use GenServer
  require Logger

  alias AppAnimal.ParagraphFocus.{Environment, Perceptual, Switchboard}
  alias AppAnimal.Neural.Oscillator
  alias Perceptual.SummarizeEdges
  require Logger
  
  # Client
  
  def start_link(paragraph_state) do
    GenServer.start_link(__MODULE__, paragraph_state)
  end
  
  # Server
  

  @impl true
  def init(paragraph_state) do
    Logger.info("focus on a new paragraph")
    Environment.start_link(paragraph_state)
    
    {:ok, _pid} = Switchboard.start_link(:ok)
    
    {:ok, _task_starter} =
      Oscillator.poke(SummarizeEdges, every: 5_000)
    {:ok, :ok}
  end


  defmacro __using__(_) do
    quote do
      alias AppAnimal.ParagraphFocus.{Control, Perceptual, Motor, Switchboard, Environment}
      alias AppAnimal.Neural
      require Logger
      use Private
    end
  end
end

