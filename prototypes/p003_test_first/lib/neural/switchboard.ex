defmodule AppAnimal.Neural.Switchboard do
  use GenServer
  require Logger

  defstruct [:environment, :network, started_circular_clusters: %{}]

  def start_link(%__MODULE__{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def send_pulse(switchboard, keys) do
    GenServer.cast(switchboard, {:send_pulse, keys})
  end

  @impl GenServer
  def init(state) do
    {:ok, state}
  end

  @impl GenServer
  def handle_cast({:send_pulse, keys}, state) do
    decoded_keys = {Keyword.fetch!(keys, :carrying),
                    Keyword.get(keys, :to, :no_destination),
                    Keyword.get(keys, :from, :no_source)}
    new_state = interior_send_pulse(decoded_keys, state)
    

    {:noreply, new_state}
  end

  def interior_send_pulse({pulse_data, :no_destination, source_name}, state) do
    destinations = state.network[source_name].downstream
    for destination <- destinations do
      
      interior_send_pulse({pulse_data, destination, :no_source}, state)
    end
    state
  end

  def interior_send_pulse({pulse_data, destination_name, :no_source}, state) do
    destination = state.network[destination_name]
    {:ok, pid} = GenServer.start(destination.__struct__, destination)
    GenServer.cast(pid, [switchboard: self(), handle_pulse: pulse_data])
    state
  end


  
  
end
