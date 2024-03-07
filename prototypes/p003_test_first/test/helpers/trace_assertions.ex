defmodule AppAnimal.TraceAssertions do
  use FlowAssertions
  use FlowAssertions.Define
  use Private
  

  def assert_log_entry(%{} = actual, %{} = expected_desc) do
    assert_same_map(actual, expected_desc)
  end

  def assert_log_entry(%{} = actual, [{name, pulse_data}]) do
    assert_fields(actual, name: name, pulse_data: pulse_data)
  end

  def assert_log_entry(%{} = actual, name) when is_atom(name) do
    assert_field(actual, name: name)
  end
  
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


  def assert_trace(_actuals, []) do
    :ok
  end

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
