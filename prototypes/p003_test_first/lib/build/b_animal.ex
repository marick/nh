defmodule AppAnimal.Builder do
  @moduledoc """
  Assemble the top-level processes into a single structure.
  """
  use AppAnimal
  use KeyConceptAliases
  alias AppAnimal.NetworkBuilder
  alias Network.Timer
  use AppAnimal.Extras.TestAwareProcessStarter

  @doc """
  Given a `NetworkBuilder` process, extract the finished network and use it to
  start all the top-level processes.

  ## Options:
    * `throb_interval:` Used by tests to make the `Timer` throb faster than normal.
      Units are milliseconds. Default is `Duration.quantum()` (100 milliseconds).
  """
  def from_network(p_network_builder, opts \\ []) when is_pid(p_network_builder) do
    s = start_processes()

    router = Moveable.Router.new(%{
                 Moveable.Action => s.p_affordland,
                 Moveable.Pulse => s.p_switchboard,
                 Moveable.Delay => s.p_timer})


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
      p_logger = compatibly_start_link(ActivityLogger, 1000)
      switchboard_struct = struct(Switchboard, p_logger: p_logger)
      p_switchboard = compatibly_start_link(Switchboard, switchboard_struct)
      p_affordland = compatibly_start_link(AffordanceLand,
                                            %{p_switchboard: p_switchboard,
                                              p_logger: p_logger})
      p_timer = compatibly_start_link(Timer, :ok)

      struct(AppAnimal.Pids, p_switchboard: p_switchboard,
                             p_affordland: p_affordland,
                             p_logger: p_logger,
                             p_timer: p_timer)
    end
  end
end
