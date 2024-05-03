alias AppAnimal.Network

defmodule Network.TimerTest do
  use AppAnimal.Case, async: true
  alias Network.Timer, as: UT
  alias System.Pulse

  test "repeating" do
    pid = start_link_supervised!(UT)

    assert :ok == UT.begin_throbbing(pid, every: 10, notify: self())

    assert_receive_cast(:time_to_throb)
    assert_receive_cast(:time_to_throb)
    assert_receive_cast(:time_to_throb)
  end

  test "one_shot" do
    pid = start_link_supervised!(UT)
    pulse = Pulse.new("payload")

    assert :ok == UT.delayed(pid, pulse, after: 10, destination: :name,
                                  via_switchboard: self())

    assert_receive(_) |> assert_distribute_to(pulse: pulse, to: [:name])

    refute_receive(_)
  end
end
