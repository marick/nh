defmodule AppAnimal do
  alias AppAnimal.System
  alias System.{Switchboard, AffordanceLand, Network, ActivityLogger}
  use AppAnimal.Extras.TestAwareProcessStarter
  use TypedStruct
  alias Network.Make

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :p_switchboard, pid, required: true
    field :p_affordances, pid, required: true
    field :p_logger,      pid, required: true
  end

  def enliven(trace_or_network, options \\ [])

  def enliven(trace, options)               when is_list(trace) do
    Make.trace(trace) |> enliven(options)
  end

  def enliven(network, switchboard_options) when is_map(network) do
    {:ok, p_logger} = ActivityLogger.start_link
    switchboard_struct = struct(Switchboard,
                                Keyword.merge(switchboard_options,
                                              p_logger: p_logger))
    p_switchboard = compatibly_start_link(Switchboard, switchboard_struct)
    p_affordances = compatibly_start_link(AffordanceLand,
                                            %{p_switchboard: p_switchboard,
                                              p_logger: p_logger})

    router = System.Router.new(%{
                 System.Action => p_affordances,
                 System.Pulse => p_switchboard})

    Network.put_routers(network, router)
    |> then(& GenServer.call(p_switchboard, accept_network: &1))

    %__MODULE__{
      p_switchboard: p_switchboard,
      p_affordances: p_affordances,
      p_logger: p_logger
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
