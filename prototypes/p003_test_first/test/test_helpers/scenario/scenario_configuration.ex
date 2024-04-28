alias AppAnimal.{Extras,System,Scenario}

defmodule Scenario.Configuration do
  use AppAnimal
  alias AppAnimal.NetworkBuilder, as: NB
  use Extras.TestAwareProcessStarter
  alias ClusterCase.Helpers, as: LessGrotty
  alias System.{CannedResponse}
  import Scenario.ProcessKludgery

  defmacro configuration(opts \\ [], do: body) do
    [terminal_log?] = Opts.parse(opts, [terminal_log: false])
    quote do
      init_network_builder compatibly_start_link(NB, :ok)
      init_affordance_thunks()
      unquote(body)
      animal = AppAnimal.from_network(network_builder())
      if unquote(terminal_log?),
         do: System.ActivityLogger.spill_log_to_terminal(animal.p_logger)
      for thunk <- affordance_thunks() do
        thunk.(animal)
      end
      provocation_thunk().(animal)
      init_animal(animal)
    end
  end

  # Having to do with the network

  def cluster(cluster) do
    NB.cluster(network_builder(), cluster)
  end

  def branch(at: name, with: list) do
    NB.branch(network_builder(), at: name, with: list)
  end

  def trace(list) do
    NB.trace(network_builder(), list)
  end

  # Scripting AffordanceLand behavior

  def respond_to_action(action, canned_response) do
    f = fn aa -> LessGrotty.respond_to_action(aa, action, canned_response) end
    append_affordance_thunk(f)
  end

  def by_sending_cluster(downstream, data), do: CannedResponse.new(downstream, data)
end
