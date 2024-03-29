defmodule ClusterCase do
  @moduledoc """
  Use this package to get various conveniences for working with clusters, message sending,
  the Switchboard, and AffordanceLand.
  """
  use AppAnimal
  alias AppAnimal.{System, Cluster}
  alias System.{Switchboard,AffordanceLand}
  alias Cluster.Shape
  alias ExUnit.Assertions

  # About the network

  @doc """
  Create a pseudo-cluster that will relay a pulse to the current test.

  Catch the pulse with `assert_test_receives` (layered on `assert_receive`).

  By default, the cluster is named `:endpoint`. If you use `to_test` more
  when making the network, you'll probably want to give a different name.
  """
  def to_test(name \\ :endpoint) do
    p_test = self()
    f_send_to_test = fn pulse_data ->
      send(p_test, [pulse_data, from: name])
    end
      
    %Cluster{name: name,
             label: :test_endpoint,
             shape: Shape.Linear.new,
             calc: &Function.identity/1,
             f_outward: f_send_to_test}
  end

  @doc "Receive a pulse from a `to_test` node"
  defmacro assert_test_receives(value, opts \\ [from: :endpoint]) do
    quote do 
      [retval, from: _] = Assertions.assert_receive([unquote(value) | unquote(opts)])
      retval
    end
  end

  @doc "Send the pulse from the test as if it came from a network cluster."
  def send_test_pulse(p_switchboard, to: destination_name, carrying: pulse_data) do
    Switchboard.cast__distribute_pulse(p_switchboard,
                                       carrying: pulse_data, to: [destination_name])
  end

  def produce_affordance(p_affordances, [{_name, _data}] = arg),
      do: AffordanceLand.cast__produce_affordance(p_affordances, arg)

  @doc """
  Script AffordanceLand to respond to a given action with a given affordance+data.

  Typically:

      |> script(
           response_to(:focus_on_paragraph, affords(paragraph_text: "some text")))
      |> take_action(focus_on_paragraph: :no_data)

  """
  def script(pid, {_action_name, {_affordance_name, _affordance_data}} = singleton), 
      do: script(pid, [singleton])
  
  def script(pid, list) do
    GenServer.cast(pid, [script: list])
    pid
  end

  def affords([{name, data}]), do: {name, data}
  def response_to(action, response), do: {action, response}


  @doc """
  Cast a message representing an action to AffordanceLand from a test.

  Behaves the same way as an `action_edge` cluster.
  """
  def take_action(pid, [{_name, _data}] = action),
      do: GenServer.cast(pid, [:take_action, action])

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
