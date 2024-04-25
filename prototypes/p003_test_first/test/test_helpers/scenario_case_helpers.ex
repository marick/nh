defmodule ScenarioCase.Helpers do
  @moduledoc """
  Use this package to get various conveniences for working with clusters, message sending,
  the Switchboard, and AffordanceLand.
  """
  use AppAnimal
  alias AppAnimal.{System,Extras}
  alias AppAnimal.NetworkBuilder.Process, as: NB
  alias System.{CannedResponse}
  alias ExUnit.Assertions
  alias AppAnimal.ClusterBuilders, as: C
  alias ClusterCase.Helpers, as: LessGrotty
  use Extras.TestAwareProcessStarter
#  import ExUnit.Callbacks

  def forward_to_test(name \\ :endpoint) do
    p_test = self()

    # Normally, a pulse is sent *after* calculation. Here, we have the
    # cluster not calculate anything but just send to the test pid.
    # That's because the `System.Router` only knows how to do GenServer-type
    # casting.
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

  @doc """
  Script AffordanceLand to respond to a given action with a given affordance+data.

  Typically:

      p_affordances
      |> respond_to_action(:focus_on_paragraph,
                           by_sending_cluster(:paragraph_text, "some text"))


      # later
      take_action(p_affordances, focus_on_paragraph: :no_data)

  """

  def respond_to_action(action, canned_response) do
    f = fn aa -> LessGrotty.respond_to_action(aa, action, canned_response) end
    Process.put(:affordance_land_thunks, [f | Process.get(:affordance_land_thunks)])
  end

  def by_sending_cluster(downstream, data), do: CannedResponse.new(downstream, data)


  def take_action(opts) do
    fn aa -> LessGrotty.take_action(aa, opts) end
  end

  def cluster(cluster) do
    pid = Process.get(:p_network_builder)
    NB.cluster(pid, cluster)
  end

  def branch(at: name, with: list) do
    pid = Process.get(:p_network_builder)
    NB.branch(pid, at: name, with: list)
  end

  def animal(callback) when is_function(callback, 1) do
    ExUnit.Callbacks.start_link_supervised!(NB)
    |> callback.()
    |> AppAnimal.from_network
  end

  def animal(trace) when is_list(trace) do

    animal& NB.trace(&1, trace)
  end


  def provocation(thunk) do
    Process.put(:provocation_thunk, thunk)
  end

  defmacro scenario(do: body) do
    quote do
      Process.put(:p_network_builder, compatibly_start_link(NB, :ok))
      Process.put(:affordance_land_thunks, [])
      unquote(body)
      aa = AppAnimal.from_network(Process.get(:p_network_builder))
      for thunk <- Enum.reverse(Process.get(:affordance_land_thunks)) do
        thunk.(aa)
      end
      Process.get(:provocation_thunk).(aa)
      aa
    end
  end
end
