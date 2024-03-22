alias AppAnimal.Cluster


defmodule Cluster do
  use AppAnimal
  use TypedStruct
  import Lens.Macros
  alias Cluster.Shape

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    # Set first thing
    field :label, atom    # only for human readability
    field :name, atom
    
    # The main axes of variation
    field :shape, Shape.Circular.t | Shape.Linear.t
    field :calc, fun
    field :f_outward, fun
    
    # Set when compiled into a network
    field :downstream, [atom], default: []
  end

  def can_throb?(s_cluster) do
    case s_cluster.shape do
      %Shape.Circular{} -> true
      %Shape.Linear{} -> false
    end
  end
  
  deflens l_never_throbs(), do: Lens.filter(& can_throb?(&1) == false)

  def start_throbbing(s_cluster) do
    starting_state = Cluster.CircularProcess.State.from_cluster(s_cluster)
    {:ok, pid} = GenServer.start(Cluster.CircularProcess, starting_state)
    Process.monitor(pid)
    {s_cluster.name, pid}
  end

  def start_pulse_on_its_way(s_cluster, pulse_data) do
    s_cluster.f_outward.(pulse_data)
  end
end
