defmodule AppAnimal.ParagraphFocus.Motor.MakeEditTypeExplicit do
  use AppAnimal.ParagraphFocus
  use AppAnimal.Neural.CircularCluster, switchboard: Switchboard

  # def tick_after(millis), do: Process.send_after(self(), :tick, millis)

  def init(signal) do 
    Logger.info("unimplemented for #{inspect signal}")
    {:ok, signal}
  end


end

# defmodule Caller do
#   use AppAnimal.ParagraphFocus
#   use GenServer

#   def init(:ok) do
#     Logger.info("caller")
#     {:ok, pid} = GenServer.start(AppAnimal.ParagraphFocus.Motor.MakeEditTypeExplicit, :ok) |> IO.inspect
#     Process.monitor(pid) |> IO.inspect
#     {:ok, pid}
#   end

# end
