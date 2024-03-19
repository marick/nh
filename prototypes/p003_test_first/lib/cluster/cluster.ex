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


  def can_be_active?(struct), do: Cluster.Shape.can_be_active?(struct.shape)
  deflens l_never_active(), do: Lens.filter(& can_be_active?(&1) == false)

  def activate(struct) do
    starting_state = Cluster.CircularProcess.State.from_cluster(struct)
    {:ok, pid} = GenServer.start(Cluster.CircularProcess, starting_state)
    Process.monitor(pid)
    {struct.name, pid}
  end

end
