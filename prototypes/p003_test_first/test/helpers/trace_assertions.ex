defmodule AppAnimal.TraceAssertions do
  use AppAnimal
  use FlowAssertions
  use FlowAssertions.Define
  use Private
  alias AppAnimal.Neural.ActivityLogger
  alias ActivityLogger.{FocusReceived, PulseSent}

  def focus_on(name), do: [FocusReceived, name]

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
  
  def assert_log_entry(%FocusReceived{} = actual, [FocusReceived, name] = _expected_desc) do
    assert_field(actual, name: name)
  end

  def assert_log_entry(%struct_type{}, [entry_type | _desc]) do
    struct_name = Pretty.Module.minimal(struct_type)
    entry_name = Pretty.Module.minimal(entry_type)
    flunk("The expectation, for a #{entry_name}, cannot match a #{struct_name}.")
  end

  def assert_log_entry(%struct_type{}, entry_desc) do
    struct_name = Pretty.Module.minimal(struct_type)
    elaborate_flunk("The expectation cannot match a #{struct_name}.",
                    right: entry_desc)
  end


  # Assert_exact_trace

  def assert_exact_trace(actuals, expecteds) do
    difference = length(actuals) - length(expecteds)
    if difference < 0, 
       do: flunk("The right-hand side has #{-difference} extra value(s).")
    if difference > 0, 
       do: flunk("The left-hand side has #{difference} extra value(s).")

    for {actual, expected} <- Enum.zip(actuals, expecteds) do
      assert_log_entry(actual, expected)
    end
  end


  # Assert_trace
  def assert_trace(_actuals, []), do: :ok

  def assert_trace([], [e | _e_rest]) do
    name = appropriate_name(e)
    elaborate_flunk("There is no entry matching `#{inspect name}`.",
                    right: e)
  end

  def assert_trace([a | a_rest], [e | e_rest] = expecteds) do
    if entry_match?(a, e) do
      assert_trace(a_rest, e_rest)
    else
      assert_trace(a_rest, expecteds)
    end
  end

  private do
    def entry_match?(a, name) when is_atom(name),
        do: a.name == name
    def entry_match?(a, [{name, pulse_data}]),
        do: a.name == name && a.pulse_data == pulse_data

    def appropriate_name([{name, _}]), do: name
    def appropriate_name( name    ), do: name
  end
  
  
end
