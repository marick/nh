defmodule AppAnimal do
  alias AppAnimal.Neural
  alias Neural.{Switchboard, AffordanceLand, Network, ActivityLogger}
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
    {:ok, logger_pid} = ActivityLogger.start_link
    switchboard_struct = struct(Switchboard,
                                Keyword.merge(switchboard_options,
                                              network: network,
                                              logger_pid: logger_pid))
    switchboard_pid = compatibly_start_link(Switchboard, switchboard_struct)
    affordances_pid = compatibly_start_link(AffordanceLand,
                                            %{switchboard_pid: switchboard_pid,
                                              logger_pid: logger_pid})

    Switchboard.link_clusters_to_pids(switchboard_pid, affordances_pid)
    %{switchboard_pid: switchboard_pid,
      affordances_pid: affordances_pid,
      logger_pid: logger_pid
    }
  end

  def switchboard(network, options \\ []), do: enliven(network, options).switchboard_pid
  def affordances(network), do: enliven(network).affordances_pid

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
    end
  end
end
