defmodule AppAnimal do
  alias AppAnimal.System
  alias System.{Switchboard, AffordanceLand, Network, ActivityLogger}
  import Private
  use AppAnimal.Extras.TestAwareProcessStarter

  defmodule Accumulator do
    defstruct [:network, switchboard_keys: []]
  end

  def enliven(trace_or_network, options \\ [])

  def enliven(trace, options)               when is_list(trace) do
    Network.trace(trace) |> enliven(options)
  end

  def enliven(network, switchboard_options) when is_map(network) do
    {:ok, p_logger} = ActivityLogger.start_link
    switchboard_struct = struct(Switchboard,
                                Keyword.merge(switchboard_options,
                                              network: network,
                                              p_logger: p_logger))
    p_switchboard = compatibly_start_link(Switchboard, switchboard_struct)
    p_affordances = compatibly_start_link(AffordanceLand,
                                            %{p_switchboard: p_switchboard,
                                              p_logger: p_logger})

    GenServer.call(p_switchboard,
                   {:link_clusters_to_architecture, p_switchboard, p_affordances})
    %{p_switchboard: p_switchboard,
      p_affordances: p_affordances,
      p_logger: p_logger
    }
  end

  def switchboard(network, options \\ []), do: enliven(network, options).p_switchboard
  def affordances(network), do: enliven(network).p_affordances

  private do
    def default_start(module, initial_mutable) do
      GenServer.start_link(module, initial_mutable)
    end
  end

  defmacro __using__(_) do
    quote do
      require Logger
      use Private
      alias AppAnimal.Map2
      alias AppAnimal.Pretty
      import AppAnimal.Extras.Tuples
      import AppAnimal.Extras.Kernel
      alias AppAnimal.Cluster
      import Lens.Macros
    end
  end
end
