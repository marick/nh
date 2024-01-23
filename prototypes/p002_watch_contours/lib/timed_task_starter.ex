defmodule AppAnimal.TimedTaskStarter do
  use GenServer
  require Logger

   # Client

  def poke(module, every: millis) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, %{task: module, millis: millis})
   end


   # Server

  @impl true
  def init(%{task: task, millis: millis}) do
    Logger.info("timed_task_server")

    runner = fn ->
      apply(task, :activate, [])
    end

    tick_after(millis)
    {:ok, %{runner: runner, time: millis}}
  end


  @impl true
  def handle_info(:tick, state) do
    IO.inspect state
    Logger.info("tick")
    Task.async(state.runner) |> IO.inspect
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
