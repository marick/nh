alias AppAnimal.Cluster
alias Cluster.Shape

defprotocol Shape do
  @type process_map :: %{atom => pid}

  @spec ensure_ready(Shape.t, Cluster.Base.t, Variations.process_map) :: Variations.process_map
  def ensure_ready(struct, cluster, started_processes)
  
  @spec generic_pulse(struct, Cluster.Base.t, pid, any) :: no_return
    def generic_pulse(struct, cluster, pid, pulse_data)
end

##


defmodule Shape.Circular do
  defstruct [starting_pulses: 20, initial_value: %{}]
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defimpl Shape, for: Shape.Circular do
  alias AppAnimal.Neural.CircularCluster

  def ensure_ready(_struct, cluster, started_processes_by_name) do
    case Map.has_key?(started_processes_by_name, cluster.name) do
      true ->
        started_processes_by_name
      false ->
        {:ok, pid} = GenServer.start(CircularCluster, cluster)
        Process.monitor(pid)
        Map.put(started_processes_by_name, cluster.name, pid)
    end
  end
  
  def generic_pulse(_struct, _cluster, destination_pid, pulse_data) do
    GenServer.cast(destination_pid, [handle_pulse: pulse_data])
  end
end

## 

defmodule Shape.Linear do
  defstruct [:dummy]
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
  
end

defimpl Shape, for: Shape.Linear do
  alias Cluster.PulseLogic
  
  def ensure_ready(_struct, _cluster, started_processes_by_name) do
    started_processes_by_name
  end
  
  def generic_pulse(_struct, cluster, _destination_pid, pulse_data) do
    Task.start(fn ->
      outgoing_data = cluster.calc.(pulse_data)
      PulseLogic.send_pulse(cluster.pulse_logic, outgoing_data)
    end)
  end    
end
