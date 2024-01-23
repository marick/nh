defmodule AppAnimal.TimedTaskStarter do
  alias AppAnimal.WithoutReply
  use GenServer
  require Logger
  

   # Interface to other processes

  def poke(module, every: millis) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, %{task: module, delay: millis})
   end

   # Code that runs within this process

  @impl true
  def init(state) do
    tick_after(state.delay)
    {:ok, state}
  end

  def tick_after(millis), do: Process.send_after(self(), :tick, millis)

  @impl true
  def handle_info(:tick, state) do
    WithoutReply.activate(state.task)
    tick_after(state.delay)
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
