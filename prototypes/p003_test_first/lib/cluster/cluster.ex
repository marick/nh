alias AppAnimal.Cluster


defmodule Cluster do
  use AppAnimal
  alias Cluster.CircularProcess
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :_

    # Set first thing
    field :label, atom    # only for human readability
    field :name, atom
    
    # The main axes of variation
    field :shape, Cluster.Shape.t
    field :calc, fun
    field :pulse_logic, atom | Cluster.PulseLogic.t, default: :installed_later

    # Set when compiled into a network
    field :downstream, [atom], default: []

    ### These are to be gotten rid of
    field :handlers, %{atom => fun}
    field :send_pulse_downstream, atom | fun, default: :installed_by_switchboard
  end

  def _pid(), do: Lens.seq(_shape(), Cluster.Shape.Circular._pid())


  # I could push the polymorphism down into the Cluster.Shape protocol, but this
  # is really a cluster-wide behavior, given that the data to initialize the
  # new process is collected from this entire cluster. 

  def ensure_ready(%{shape: %Cluster.Shape.Circular{}} = cluster) do
    case cluster.shape.pid do
      nil -> 
        starting_state = CircularProcess.State.from_cluster(cluster)
        {:ok, new_pid} = GenServer.start(CircularProcess, starting_state)
        Process.monitor(new_pid)
        deeply_put(cluster, :_pid, new_pid)
      pid when is_pid(pid) ->
        cluster
    end
  end
  
  def ensure_ready(%{shape: %Cluster.Shape.Linear{}} = cluster) do
    cluster
  end

  def unready(%{shape: %Cluster.Shape.Circular{}} = cluster) do
    deeply_put(cluster, :_pid, nil)
  end
end



