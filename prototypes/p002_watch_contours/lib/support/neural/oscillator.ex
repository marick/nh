defmodule AppAnimal.Neural.Oscillator do
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
    Logger.info("\n")
    Logger.info("tick!")
    runner = fn -> apply(state.task, :receive_pulse, []) end
    Task.start(runner)

    tick_after(state.delay)
    {:noreply, state}
  end
end
