alias AppAnimal.Cluster


defmodule Cluster do
  use AppAnimal
  use TypedStruct
  import Lens.Macros

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    # Set first thing
    field :label, atom    # only for human readability
    field :name, atom
    
    # The main axes of variation
    field :shape, Cluster.Shape.t
    field :calc, fun
    field :pulse_logic, atom | Cluster.PulseLogic.t, default: :installed_later

    # Set when compiled into a network
    field :downstream, [atom], default: []
  end


  def can_throb?(struct), do: Cluster.Shape.can_throb?(struct.shape)
  deflens l_never_throbs(), do: Lens.filter(& can_throb?(&1) == false)

  def start_throbbing(struct) do
    starting_state = Cluster.CircularProcess.State.from_cluster(struct)
    {:ok, pid} = GenServer.start(Cluster.CircularProcess, starting_state)
    Process.monitor(pid)
    {struct.name, pid}
  end

end
