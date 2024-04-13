alias AppAnimal.{System,Network,Cluster}

defmodule AppAnimal do
  alias System.{Switchboard, AffordanceLand, ActivityLogger}
  alias Network.{ClusterMap,Timer}
  use AppAnimal.Extras.TestAwareProcessStarter
  use TypedStruct
  import AppAnimal.Extras.Kernel

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :p_switchboard,       pid, required: true
    field :p_affordances,       pid, required: true
    field :p_logger,            pid, required: true
    field :p_circular_clusters, pid, required: true
    field :p_timer,             pid, required: true
  end

  def enliven(trace_or_network, options \\ [])

  def enliven(trace, options)               when is_list(trace) do
    ClusterMap.trace(trace) |> enliven(options)
  end

  def enliven(cluster_map, network_options) when is_map(cluster_map) do
    {:ok, p_logger} = ActivityLogger.start_link
    switchboard_struct = struct(Switchboard, p_logger: p_logger)
    p_switchboard = compatibly_start_link(Switchboard, switchboard_struct)
    p_affordances = compatibly_start_link(AffordanceLand,
                                            %{p_switchboard: p_switchboard,
                                              p_logger: p_logger})
    p_timer = compatibly_start_link(Timer, :ok)

    router = System.Router.new(%{
                 System.Action => p_affordances,
                 System.Pulse => p_switchboard,
                 System.Delay => p_timer})

    network =
      cluster_map
      |> deeply_put(Lens.map_values |> Cluster.l_router, router)
      |> Network.new(network_options)

    GenServer.call(p_switchboard, accept_network: network)

    %__MODULE__{
      p_switchboard: p_switchboard,
      p_affordances: p_affordances,
      p_circular_clusters: network.p_circular_clusters,
      p_logger: p_logger,
      p_timer: p_timer
    }
  end

  def switchboard(network, options \\ []), do: enliven(network, options).p_switchboard
  def affordances(network), do: enliven(network).p_affordances

  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      alias AppAnimal.Pretty
      import AppAnimal.Extras.Tuples
      import AppAnimal.Extras.Kernel
      alias AppAnimal.Cluster
      import Lens.Macros
      alias AppAnimal.Duration
      alias AppAnimal.Extras.Opts
    end
  end
end
