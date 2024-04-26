defmodule ScenarioCase.Helpers do
  @moduledoc """
  Use this package to get various conveniences for working with clusters, message sending,
  the Switchboard, and AffordanceLand.
  """
  use AppAnimal
  alias AppAnimal.{System,Extras}
  alias AppAnimal.NetworkBuilder, as: NB
  alias System.{CannedResponse}
  alias ExUnit.Assertions
  alias AppAnimal.ClusterBuilders, as: C
  alias ClusterCase.Helpers, as: LessGrotty
  use Extras.TestAwareProcessStarter

  @network_builder :network_builder     # get warnings about typos
  def network_builder(), do: Process.get(@network_builder)
  def init_network_builder(v), do: Process.put(@network_builder, v)

  @affordance_thunks :affordance_thunks
  def init_affordance_thunks, do: Process.put(@affordance_thunks, [])
  def affordance_thunks, do: Process.get(@affordance_thunks)
  def append_affordance_thunk(thunk),
      do: Process.put(@affordance_thunks,[thunk | affordance_thunks()])

  @provocation_thunk :provocation_thunk
  def init_provocation_thunk(thunk), do: Process.put(@provocation_thunk, thunk)
  def provocation_thunk(), do: Process.get(@provocation_thunk)

  @animal :animal
  def init_animal(aa), do: Process.put(@animal, aa)
  def animal(), do: Process.get(@animal)



  def forward_to_test(name \\ :endpoint) do
    p_test = self()

    # Normally, a pulse is sent *after* calculation. Here, we have the
    # cluster not calculate anything but just send to the test pid.
    # That's because the `System.Router` only knows how to do GenServer-type
    # casting, which is not compatible with `assert_receive`
    kludge_a_calc = fn arg ->
      send(p_test, [arg, from: name])
      :no_result
    end

    C.linear(name, kludge_a_calc, label: :test_endpoint)
  end

  @doc "Receive a pulse from a `to_test` node"
  defmacro assert_test_receives(value, opts \\ [from: :endpoint]) do
    quote do
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(opts)])
      retval
    end
  end

  def respond_to_action(action, canned_response) do
    f = fn aa -> LessGrotty.respond_to_action(aa, action, canned_response) end
    append_affordance_thunk(f)
  end

  def by_sending_cluster(downstream, data), do: CannedResponse.new(downstream, data)


  def take_action(opts) do
    fn aa -> LessGrotty.take_action(aa, opts) end
  end

  def cluster(cluster) do
    NB.cluster(network_builder(), cluster)
  end

  def branch(at: name, with: list) do
    NB.branch(network_builder(), at: name, with: list)
  end

  def provocation(thunk), do: init_provocation_thunk(thunk)

  defmacro configuration(do: body) do
    quote do
      init_network_builder compatibly_start_link(NB, :ok)
      init_affordance_thunks()
      unquote(body)
      animal = AppAnimal.from_network(network_builder())
      for thunk <- affordance_thunks() do
        thunk.(animal)
      end
      provocation_thunk().(animal)
      init_animal(animal)
    end
  end
end
