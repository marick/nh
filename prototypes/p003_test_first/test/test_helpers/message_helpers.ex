defmodule AppAnimal.TestHelpers.MessageHelpers do
  use AppAnimal
  import ExUnit.Assertions

  @cast_marker :"$gen_cast"

  defmacro assert_receive_cast(thing_being_cast) do
    quote do
      assert_receive({unquote(@cast_marker), unquote(thing_being_cast)})
    end
  end

  def assert_pulse_FROM_switchboard(message, opts) when is_tuple(message) do
    [expected_downstream, expected_pulse] = Opts.required!(opts, [:to, :pulse])
    assert {:fan_out, ^expected_pulse, to: ^expected_downstream} = ensure_unwrapped(message)
  end

  def assert_pulse_TO_switchboard(message, opts) when is_tuple(message) do
    [expected_sender, expected_pulse] = Opts.required!(opts, [:from, :pulse])

    assert {:on_behalf_of, ^expected_sender, deliver: ^expected_pulse} = ensure_unwrapped(message)
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
  end
end
