defmodule ClusterCase do
  @moduledoc """
  Use this package to get various conveniences for working with clusters, message sending,
  the Switchboard, and AffordanceLand.
  """
  use AppAnimal
  alias AppAnimal.{System, Cluster}
  alias System.{Switchboard,AffordanceLand,Pulse,CannedResponse}
  alias Cluster.Shape
  alias ExUnit.Assertions

  # How the test starts things off

  @doc """
  Send the pulse from the test as if it came from a network cluster.

  You can also use this to send a pulse to a PerceptionEdge as if it
  came from AffordanceLand, though `spontaneous_affordance` is preferable
  because it actually involves `AffordanceLand` code.

  Example:
      send_test_pulse(p_switchboard, to: :first, carrying: 1)
  """
  def send_test_pulse(p_switchboard, to: destination_name, carrying: pulse_data) do
    pulse = Pulse.new(pulse_data)
    Switchboard.cast__distribute_pulse(p_switchboard,
                                       carrying: pulse,
                                       to: [destination_name])
  end

  @doc """
  Cause `AffordanceLand` to send a pulse to the given `PerceptionEdge`.
  
  Example:
      spontaneous_affordance(p_affordances, named: affordance_name, carrying: data)

  The affordance will be delivered to the cluster with the same name as the affordance,
  with the given data wrapped in a `Pulse`. The `carrying` argument may be omitted,
  in which case some innocuous, to-be-ignored data is sent.
  """

  def spontaneous_affordance(p_affordances, named: name),
      do: spontaneous_affordance(p_affordances, named: name, carrying: :no_pulse_data)

  def spontaneous_affordance(p_affordances, named: name, carrying: pulse_data) do
    pulse = Pulse.new(pulse_data)
    AffordanceLand.cast__produce_spontaneous_affordance(p_affordances,
                                                        named: name,
                                                        pulse: pulse)
  end



  @doc """
  Create a pseudo-cluster that will relay a pulse to the current test.

  Catch the pulse with `assert_test_receives` (layered on `assert_receive`).

  By default, the cluster is named `:endpoint`. If you use `to_test` more
  when making the network, you'll probably want to give a different name.
  """

  def to_test(name \\ :endpoint) do
    p_test = self()

    # Normally, a pulse is sent *after* calculation. Here, we have the
    # cluster not calculate anything but just send to the test pid.
    # That's because the `System.Router` only knows how to do GenServer-type
    # casting.
    kludge_a_calc = fn arg ->
      send(p_test, [arg, from: name])
      :no_result
    end
      
    %Cluster{name: name,
             label: :test_endpoint,
             shape: Shape.Linear.new,
             calc: kludge_a_calc}
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

  ### Note that this needs only a small tweak to allow multiple canned responses (sending
  ### to different clusters) for a single action.
  
  def respond_to_action(p_affordances, action_name, %CannedResponse{} = canned_response) do
    GenServer.cast(p_affordances, {:respond_to, action_name, [canned_response]})
    p_affordances
  end

  def by_sending_cluster(downstream, data), do: CannedResponse.new(downstream, data)

  @doc """
  Cast a message representing an action to AffordanceLand from a test.

  Behaves the same way as an `action_edge` cluster.
  """
  def take_action(pid, [{type, data}]) do
    action = System.Action.new(type, data)
    GenServer.cast(pid, {:take_action, action})
  end

  @doc """
  Used by tests to synchronously access one active process's internal state.
  """
  def peek_at(p_switchboard, internal_state_name, of: cluster_name),
      do: GenServer.call(p_switchboard, forward: internal_state_name, to: cluster_name)

  @doc ""
  def throb_all_active(p_switchboard),
      do: send(p_switchboard, :time_to_throb)

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      alias AppAnimal.System
      alias System.Switchboard
      alias System.AffordanceLand
      alias System.Network
      alias System.ActivityLogger
      import ClusterCase
      import AppAnimal.ActivityLogAssertions
      use FlowAssertions
      import Cluster.Make
      import Network.Make
      alias AppAnimal.Duration
    end
  end
end
