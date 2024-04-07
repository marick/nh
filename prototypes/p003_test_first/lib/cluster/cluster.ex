alias AppAnimal.{Cluster, System}

defmodule Cluster do

  @moduledoc """
  This represents a linear or circular cluster as represented within a network
  of connected processes.

  This function violates that "initialize every field at `new` time guideline
  in two ways.

  1. Network construction is vaguely graphical. Even though a particular cluster
     appears only once in the network, it may be mentioned several times as
     the network is being constructed:

           popular = circular_cluster(:popular)

           network = 
             Network.trace(linear(..1..), popular, linear(..2..))
             |> Network.trace(linear(..3..), popular, linear(..4..))

     Because of that, it's not known at creation time that `popular` is upstream
     of both `..2..` and `..4..`. Practically, this means that a clusters
     `downstream` field is built up as the network is constructed.

  2. When a process sends a pulse downstream, it goes to either the `Switchboard` or
     to `AffordanceLand`. Each of those is created *after* the network. (That is,
     *they* are completely initialized at `new` time. Because the whole system
     is circular, *something* has to be updated after creation. It was perhaps a mistake
     to make it the cluster. Oh well.)

     This affects the `f_outward` function, which is used to send a pulse downstream. It
     seems cleanest for that function to be created in two stages. In the first stage,
     `f_outward` is bound to a function that takes a pid. When later called with either
     the Switchboard or AffordanceLand pid, `f_outward` creates a new function that
     sends appropriately to that pid. That function is then bound to the `f_outward`
     field. 
     
     This is not entirely pleasing.

     (`f_outward`` is also used to send pulses to a currently-running test,
     but in that case the pid is known before the cluster is created.)  
  """

  
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
    field :router, System.Router.t
    field :downstream, [atom], default: []
  end

  deflens l_never_throbs(), do: Lens.filter(& can_throb?(&1) == false)

  def can_throb?(s_cluster) do
    case s_cluster.shape do
      %Shape.Circular{} -> true
      %Shape.Linear{} -> false
    end
  end
  
  def start_throbbing(s_cluster) do
    starting_state = Cluster.CircularProcess.State.from_cluster(s_cluster)
    {:ok, pid} = GenServer.start(Cluster.CircularProcess, starting_state)
    Process.monitor(pid)
    {s_cluster.name, pid}
  end

  def start_pulse_on_its_way(s_cluster, %System.Pulse{} = pulse) do
    router = s_cluster.router
    System.Router.cast_via(router, pulse, from: s_cluster.name)
#    s_cluster.f_outward.(pulse_data)
  end


  def start_pulse_on_its_way(s_cluster, %System.Action{} = action) do
    router = s_cluster.router
    System.Router.cast_via(router, action)
  end

end
