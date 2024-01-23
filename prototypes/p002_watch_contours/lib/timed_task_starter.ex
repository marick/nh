defmodule AppAnimal.TimedTaskStarter do
  use GenServer
  require Logger

   # Client

   def start_link(task_info) do
     GenServer.start_link(__MODULE__, task_info)
   end


   # Server

  @impl true
  def init(with: task, every: millis) do
    Logger.info("timed_task_server")

    runner = fn ->
      apply(task, :activate, []) |> IO.inspect
    end

    tick_after(millis)
    {:ok, %{runner: runner, time: millis}}
  end


  @impl true
  def handle_info(:tick, state) do
    IO.inspect state
    Logger.info("tick")
    Task.async(state.runner)
    tick_after(state.time)
    {:noreply, state}
  end

  @impl true
  def handle_info({ref, result}, state) do
    Logger.info("received #{inspect ref}, #{inspect result}")
    {:noreply, state}
  end
  
  @impl true
  def handle_info({:DOWN, ref, :process, _pid, reason}, state) do
    Logger.info("received #{inspect ref}, #{inspect reason}")
    {:noreply, state}
  end
  


  def tick_after(millis), do: Process.send_after(self(), :tick, millis)

end
