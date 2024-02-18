defmodule AppAnimal.ParagraphFocus.Motor.MakeEditTypeExplicit do
  use AppAnimal.ParagraphFocus
  use GenServer

  def start_appropriately(small_data), do: activate(small_data)

  def activate(signal) do
    GenServer.start_link(__MODULE__, signal)
  end

  # def tick_after(millis), do: Process.send_after(self(), :tick, millis)

  def init(signal) do 
    Logger.info("unimplemented for #{inspect signal}")
    # tick_after(1_000)
    {:ok, signal}
  end


  # def handle_info(:tick, state) do
  #   Logger.info("\n")
  #   Logger.info("tick!")
  #   {:stop, :normal, state}
  # end  
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

#   def handle_info(arg, pid) do
#     IO.inspect arg
#     IO.inspect pid
#     {:stop, :normal, pid}
#   end
# end
