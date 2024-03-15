alias AppAnimal.Cluster
alias Cluster.Shape
alias AppAnimal.Switchboard

defprotocol Shape do
  @spec ensure_ready(Shape.t, Cluster.t, Switchboard.process_map) :: Switchboard.process_map
  def ensure_ready(struct, cluster, started_processes)
  
  @spec accept_pulse(struct, Cluster.t, pid, any) :: no_return
    def accept_pulse(struct, cluster, pid, pulse_data)
end

##


defmodule Shape.Circular do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :_

    field :starting_pulses, integer, default: 20
    field :initial_value, any, default: %{}
    field :pid, pid
  end
  
  def new(opts \\ []), do: struct(__MODULE__, opts)
end

defimpl Shape, for: Shape.Circular do
  alias AppAnimal.Cluster.CircularProcess

  def ensure_ready(_struct, cluster, started_processes_by_name) do
    case Map.has_key?(started_processes_by_name, cluster.name) do
      true ->
        started_processes_by_name
      false ->
        starting_state = CircularProcess.State.from_cluster(cluster) # |> IO.inspect
        {:ok, pid} = GenServer.start(CircularProcess, starting_state) # |> IO.inspect
        Process.monitor(pid)
        Map.put(started_processes_by_name, cluster.name, pid)
    end
  end
  
  def accept_pulse(_struct, _cluster, destination_pid, pulse_data) do
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

  def accept_pulse(_struct, cluster, _destination_pid, pulse_data) do
    Task.start(fn ->
      outgoing_data = cluster.calc.(pulse_data)
      PulseLogic.send_pulse(cluster.pulse_logic, outgoing_data)
    end)
  end    
end
