defmodule AppAnimal.Neural.Switchboard do
  use GenServer
  require Logger

  defstruct [:environment, :network, started_circular_clusters: %{}]

  def start_link(%__MODULE__{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def send_pulse(switchboard, keys) do
    GenServer.cast(switchboard, {:receive_pulse, keys})
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:receive_pulse, keys}, state) do
    decoded_keys = {Keyword.fetch!(keys, :carrying),
                    Keyword.get(keys, :to, :no_destination),
                    Keyword.get(keys, :from, :no_source)}
    new_state = receive_pulse(decoded_keys, state)
    {:noreply, new_state}
  end

  def receive_pulse({pulse_data, :no_destination, source_name}, state) do
    destinations = state.network[source_name].downstream
    for destination <- destinations do
      receive_pulse({pulse_data, destination, :no_source}, state)
    end
    state
  end

  def receive_pulse({pulse_data, destination_name, :no_source} = args, state) do
    destination = state.network[destination_name]
    case get_in(state, [Access.key!(:started_circular_clusters), destination_name]) do
      nil ->
        {:ok, pid} = GenServer.start(destination.__struct__, destination)
        new_state = put_in(state.started_circular_clusters[destination_name], pid)
        receive_pulse(args, new_state)
      pid -> 
        GenServer.cast(pid, [switchboard: self(), handle_pulse: pulse_data])
        state
    end
  end    
end
