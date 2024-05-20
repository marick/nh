defmodule AppAnimal.TestHelpers.MessageHelpers do
  use AppAnimal
  import ExUnit.Assertions

  @cast_marker :"$gen_cast"

  defmacro assert_receive_cast(thing_being_cast) do
    quote do
      assert_receive({unquote(@cast_marker), unquote(thing_being_cast)})
    end
  end

  def assert_distribute_to({@cast_marker, value}, opts),
      do: assert_distribute_to(value, opts)

  def assert_distribute_to(value, opts) do
    if Keyword.has_key?(opts, :to),
       do: assert distribute_pulse_destinations(value) == Keyword.fetch!(opts, :to)

    if Keyword.has_key?(opts, :pulse),
       do: assert distribute_what_to(value) == Keyword.fetch!(opts, :pulse)
  end


  def assert_distribute_from({@cast_marker, value}, opts),
      do: assert_distribute_from(value, opts)

  def assert_distribute_from(value, opts) do
    if Keyword.has_key?(opts, :from),
       do: assert distribute_pulse_source(value) == Keyword.fetch!(opts, :from)

    if Keyword.has_key?(opts, :pulse),
       do: assert distribute_what_from(value) == Keyword.fetch!(opts, :pulse)
  end


  def assert_action_taken({@cast_marker, value}, opts),
      do: assert_action_taken(value, opts)

  def assert_action_taken(value, expected_action) do
    {:take_action, actual_action} = value

    assert actual_action == expected_action
  end

  private do
    def distribute_what_to(           {:distribute_pulse, carrying: pulse, to: _}),
        do: pulse
    def distribute_pulse_destinations({:distribute_pulse, carrying: _,     to: destinations}),
        do: destinations

    def distribute_what_from(   {:distribute_pulse, carrying: pulse, from: _}),
        do: pulse
    def distribute_pulse_source({:distribute_pulse, carrying: _,     from: source}),
        do: source
  end
end
