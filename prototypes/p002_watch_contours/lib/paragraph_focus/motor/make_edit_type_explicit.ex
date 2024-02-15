defmodule AppAnimal.ParagraphFocus.Motor.MakeEditTypeExplicit do
  use AppAnimal.ParagraphFocus
  use GenServer

  def do_the_start_thing(_small_data), do: activate(:ok)

  def activate(:ok) do
    GenServer.start_link(__MODULE__, :ok)
  end


  def init(:ok) do 
    Logger.info("unimplemented")
    {:ok, :ok}
  end
end
