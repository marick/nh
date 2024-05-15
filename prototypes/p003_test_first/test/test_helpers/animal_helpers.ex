defmodule AppAnimal.TestHelpers.Animal do
  @moduledoc """
  Use this package to get various conveniences for working an animal as a whole
  """
  use AppAnimal
  use KeyConceptAliases
  use MoveableAliases

  # How the test starts things off

  @doc """
  Send the pulse from the test as if it came from a network cluster.

  You can also use this to send a pulse to a PerceptionEdge as if it
  came from AffordanceLand, though `spontaneous_affordance` is preferable
  because it actually involves `AffordanceLand` code.

  Example:
      send_test_pulse(p_switchboard, to: :first, carrying: 1)
  """
  def send_test_pulse(%AppAnimal{} = pids, to: destination_name, carrying: pulse_data) do
    send_test_pulse(pids.p_switchboard, to: destination_name, carrying: pulse_data)
  end

  def send_test_pulse(p_switchboard, to: destination_name, carrying: pulse_data) do
    pulse = Pulse.new(pulse_data)
    Switchboard.cast(p_switchboard, :distribute_pulse, carrying: pulse,
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
  def spontaneous_affordance(%AppAnimal{} = pids, opts),
      do: spontaneous_affordance(pids.p_affordances, opts)

  def spontaneous_affordance(p_affordances, opts) when is_pid(p_affordances) do
    [name, data] = Opts.parse(opts, [:named, carrying: Pulse.new])
    AffordanceLand.cast(p_affordances, :pulse_to_cluster,
                        to_cluster: name,
                        pulse: Pulse.ensure(data))
  end

  ### Note that this needs only a small tweak to allow multiple canned responses (sending
  ### to different clusters) for a single action.

  def respond_to_action(%AppAnimal{} = pids, action_name, canned_response) do
    respond_to_action(pids.p_affordances, action_name, canned_response)
  end

  def respond_to_action(p_affordances, action_name, %Moveable.ScriptedReaction{} = affordance) do
    GenServer.cast(p_affordances, {:respond_to, action_name, [affordance]})
    p_affordances
  end

  @doc """
  Cast a message representing an action to AffordanceLand from a test.

  Behaves the same way as an `action_edge` cluster.
  """
  def take_action(%AppAnimal{} = animal, action_name) when is_atom(action_name),
      do: take_action(animal.p_affordances, [{action_name, :no_data}])

  def take_action(%AppAnimal{} = animal, opts),
      do: take_action(animal.p_affordances, opts)

  def take_action(p_affordances, [{action_name, data}]) do
    action = Action.new(action_name, data)
    GenServer.cast(p_affordances, {:take_action, action})
  end

  @doc """
  Used by tests to synchronously access one active process's internal state.

  This applies only to throbbing clusters, since only they have state. Note also that
  the process better be running
  """
  def peek_at(%AppAnimal{} = animal, internal_state_name, of: cluster_name),
      do: GenServer.call(animal.p_circular_clusters,
                         forward: internal_state_name, to: cluster_name)

  @doc """
  Instruct all throbbing clusters to take a throb.
  """
  def throb_all_active(%AppAnimal{} = animal),
      do: GenServer.cast(animal.p_circular_clusters, :time_to_throb)
end
