defmodule AppAnimal.ActivityLogAssertions do
  @moduledoc """
  Some fairly rudimentary assertions against the log. Perhaps more to come.
  """
               
  
  use AppAnimal
  use FlowAssertions
  use FlowAssertions.Define
  use Private
  alias AppAnimal.System.ActivityLogger
  alias ActivityLogger.{ActionReceived, PulseSent}

  @doc "shorthand for an action received"
  def action_taken(name, data \\ :no_data), do: ActionReceived.new(name, data)


  @doc """
  Assert that one set of pulses and actions appear in the activity log. It's assumed
  that each entry caused the next one.

  A log is compared to a set of expected entries. An entry can signify an
  action received by AffordanceLand, or it can be a pulse sent by a cluster.
  A log entry that doesn't match the expected entry is skipped without causing the
  assertion to fail. 

  Most entries will be pulses sent, so there is shorthand.

  * A lone atom asserts a cluster with that name pulsed unspecified data.
  * A two element list gives both the cluster name and the pulse data.

  For example: `assert_causal_chain(log, [:a_name, [b_name: "b_data"], :c_name])

  An action taken can be a bare name, or a name plus data, represented like this:

       action_taken(:name)
       action_taken(:name, "data")
  """
  
  def assert_causal_chain(_actuals, []), do: :ok

  def assert_causal_chain([], [e | _e_rest]) do
    name = appropriate_name(e)
    elaborate_flunk("There is no entry matching `#{inspect name}`.",
                    right: e)
  end

  def assert_causal_chain([a | a_rest], [e | e_rest] = expecteds) do
    if entry_match?(a, e) do
      assert_causal_chain(a_rest, e_rest)
    else
      assert_causal_chain(a_rest, expecteds)
    end
  end

  private do
    def entry_match?(%a_type{} = a, %other_type{} = other),
        do: a_type == other_type && a == other
    
    def entry_match?(a, name) when is_atom(name),
        do: a.name == name
    def entry_match?(a, [{name, pulse_data}]),
        do: a.name == name && a.pulse_data == pulse_data

    def appropriate_name([{name, _}]), do: name
    def appropriate_name( name    ), do: name
  end



  @doc """
  A more exact match than `assert_causal_chain`.

  The actual values (the log's entries) must match the expected ones,
  one-to-one, no skipping. There must also be the same number of
  entries in each list.

  In addition to the expectations in `assert_causal_chain`, log
  structures, `PulseSent` and `ActionReceived` structures can be given
  when an exact match is desired. You may also pass just the name
  `PulseSent` or ActionReceived if only the type of message is needed.

  I ended up deleting whatever tests caused this code to be written,
  but I don't want to delete it yet.
  """
  def assert_log_entries(actuals, expecteds) do
    difference = length(actuals) - length(expecteds)
    if difference < 0, 
       do: flunk("The right-hand side has #{-difference} extra value(s).")
    if difference > 0, 
       do: flunk("The left-hand side has #{difference} extra value(s).")

    for {actual, expected} <- Enum.zip(actuals, expecteds) do
      assert_log_entry(actual, expected)
    end
  end
  
  # Assert_log_entry
  
  def assert_log_entry(%PulseSent{} = actual, %PulseSent{} = expected_desc) do
    assert_same_map(actual, expected_desc)
  end
  
  def assert_log_entry(%PulseSent{} = actual, [{name, pulse_data}]) do
    assert_fields(actual, name: name, pulse_data: pulse_data)
  end
  
  def assert_log_entry(%PulseSent{} = actual, name) when is_atom(name) do
    assert_field(actual, name: name)
  end
  
  def assert_log_entry(%ActionReceived{} = actual, %ActionReceived{name: name}) do
    assert_field(actual, name: name)
  end

  def assert_log_entry(%actual_type{}, %expected_type{}) do
    actual_name = Pretty.Module.minimal(actual_type)
    expected_name = Pretty.Module.minimal(expected_type)
    flunk("The expectation, for #{expected_name}, cannot match a #{actual_name}.")
  end

  def assert_log_entry(%struct_type{}, entry_desc) do
    struct_name = Pretty.Module.minimal(struct_type)
    elaborate_flunk("The expectation cannot match a #{struct_name}.",
                    right: entry_desc)
  end
end
