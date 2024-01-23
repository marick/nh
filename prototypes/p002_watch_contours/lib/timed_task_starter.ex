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

  def tick_after(millis), do: Process.send_after(self(), :tick, millis)

  @impl true
  def handle_info(:tick, state) do
    Logger.info("tick")
    Task.async(state.runner)
    tick_after(state.time)
    {:noreply, state}
  end

  # These will catch ***all*** returns from un-awaited subtasks, including
  # those started within by subtasks.
  @impl true
  def handle_info({_ref, _result}, state) do
    {:noreply, state}
  end
  
  @impl true
  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

end
