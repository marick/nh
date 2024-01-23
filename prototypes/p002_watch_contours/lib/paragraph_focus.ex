defmodule AppAnimal.ParagraphFocus do
  use GenServer
  require Logger

   alias AppAnimal.ParagraphFocus.{Environment, Perceptual} #, Control, Motor}
   alias AppAnimal.TimedTaskStarter
   alias Perceptual.EdgeDetection
   # alias Control.{AttendToEditing, AttendToFragment}
   # alias Motor.{MarkAsEditing, MoveFragment}
   require Logger

   # Client

   def start_link(paragraph_state) do
     GenServer.start_link(__MODULE__, paragraph_state)
   end


   # Server

  @impl true
  def init(paragraph_state) do
    Logger.info("paragraph_state started")
    Environment.activate(paragraph_state)
    
    {:ok, _task_starter} =
      TimedTaskStarter.poke(EdgeDetection, every: 5_000)
    {:ok, :ok}
  end
end
