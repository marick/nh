defmodule AppAnimal do
  alias AppAnimal.Neural.Switchboard
  alias AppAnimal.Neural.Affordances
  alias AppAnimal.Neural.Network
  import Private
  use AppAnimal.Extras.TestAwareProcessStarter

  defmodule Accumulator do
    defstruct [:network, switchboard_keys: []]
  end

  def enliven(trace, options \\ [])

  def enliven(trace, options)               when is_list(trace) do
    Network.trace(trace) |> enliven(options)
  end

  def enliven(network, switchboard_options) when is_map(network) do
    switchboard_struct = struct(Switchboard,
                                Keyword.put_new(switchboard_options, :network, network))
    switchboard_pid = compatibly_start_link(Switchboard, switchboard_struct)
    logger_pid = Switchboard.get_logger_pid(switchboard_pid)
    affordances_pid = compatibly_start_link(Affordances,
                                            %{switchboard: switchboard_pid,
                                            logger: logger_pid})
    {switchboard_pid, affordances_pid}
  end

  def switchboard(network, options \\ []) do
    {switchboard_pid, _} = enliven(network, options)
    switchboard_pid
  end

  def affordances(network) do
    {_, affordances_pid} = enliven(network)
    affordances_pid
  end

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
    end
  end
end
