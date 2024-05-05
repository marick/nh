alias AppAnimal.{System,Network,Cluster,Duration,NetworkBuilder}

defmodule AppAnimal do
  alias System.{Switchboard, AffordanceLand, ActivityLogger}
  alias Network.Timer
  alias AppAnimal.Extras.DepthAgnostic, as: A
  use AppAnimal.Extras.TestAwareProcessStarter
  use TypedStruct
  use Private

  typedstruct do
    plugin TypedStructLens

    field :p_switchboard,       pid
    field :p_affordances,       pid
    field :p_logger,            pid
    field :p_circular_clusters, pid
    field :p_timer,             pid
  end

  def from_network(p_network_builder, opts \\ []) when is_pid(p_network_builder) do
    s = start_processes()

    router = System.Router.new(%{
                 System.Action => s.p_affordances,
                 System.Pulse => s.p_switchboard,
                 System.Delay => s.p_timer})


    NetworkBuilder.install_routers(p_network_builder, router)
    network = NetworkBuilder.network(p_network_builder)

    finish_struct(s, network, opts)
  end

  private do

    def finish_struct(s, network, opts) do
      Switchboard.call(s.p_switchboard, :accept_network, network)
      throb_interval = Keyword.get(opts, :throb_interval, Duration.quantum())
      Network.Timer.begin_throbbing(s.p_timer, every: throb_interval,
                                               notify: network.p_circular_clusters)

      %{s | p_circular_clusters: network.p_circular_clusters}
    end

    def start_processes() do
      {:ok, p_logger} = ActivityLogger.start_link
      switchboard_struct = struct(Switchboard, p_logger: p_logger)
      p_switchboard = compatibly_start_link(Switchboard, switchboard_struct)
      p_affordances = compatibly_start_link(AffordanceLand,
                                            %{p_switchboard: p_switchboard,
                                              p_logger: p_logger})
      p_timer = compatibly_start_link(Timer, :ok)

      struct(__MODULE__, p_switchboard: p_switchboard,
                         p_affordances: p_affordances,
                         p_logger: p_logger,
                         p_timer: p_timer)
    end
  end

  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      use TypedStruct
      alias AppAnimal.Pretty
      import AppAnimal.Extras.Tuples
      import AppAnimal.Extras.Kernel
      alias AppAnimal.Extras.DepthAgnostic, as: A
      alias AppAnimal.Cluster
      alias Cluster.Identification
      import Lens.Macros
      alias AppAnimal.Duration
      alias AppAnimal.Extras.Opts
    end
  end
end
