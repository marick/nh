defmodule AppAnimal.Neural.Switchboard do
  use GenServer
  require Logger

  defstruct [:environment, :network, started_circular_clusters: %{}]

  def start_link(%__MODULE__{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def send_pulse(keys) do
    switchboard = Keyword.fetch!(keys, :via)
    small_data = Keyword.fetch!(keys, :carrying)
    destination_name = Keyword.fetch!(keys, :to)

    GenServer.call(switchboard, {:send_pulse, destination_name, small_data})
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:send_pulse, destination_name, small_data}, _from, state) do
    destination = state.network[destination_name]
    {:ok, pid} = GenServer.start(destination.__struct__, destination)

    GenServer.call(pid, [handle_pulse: small_data])
    {:reply, 5, state}
  end
end
