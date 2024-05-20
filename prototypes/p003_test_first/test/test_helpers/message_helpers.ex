defmodule AppAnimal.TestHelpers.MessageHelpers do
  use AppAnimal
  import ExUnit.Assertions

  @cast_marker :"$gen_cast"

  defmacro assert_receive_cast(thing_being_cast) do
    quote do
      assert_receive({unquote(@cast_marker), unquote(thing_being_cast)})
    end
  end

  def assert_pulse_FROM_switchboard(message, opts) do
    [expected_destination_names, expected_pulse] = Opts.required!(opts, [:to, :pulse])

    message = ensure_unwrapped(message)
    assert distribute_pulse_destinations(message) == expected_destination_names
    assert distribute_what_to(message) == expected_pulse
  end

  def assert_pulse_TO_switchboard(message, opts) do
    [expected_sender, expected_pulse] = Opts.required!(opts, [:from, :pulse])

    assert {:fan_out_pulse, ^expected_pulse, from: ^expected_sender} = ensure_unwrapped(message)
  end

  def assert_action_taken({@cast_marker, message}, opts),
      do: assert_action_taken(message, opts)

  def assert_action_taken(message, expected_action) do
    {:take_action, actual_action} = message

    assert actual_action == expected_action
  end

  private do
    def ensure_unwrapped({@cast_marker, message}), do: message
    def ensure_unwrapped(message), do: message

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
