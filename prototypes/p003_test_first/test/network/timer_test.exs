alias AppAnimal.Network

defmodule Network.TimerTest do
  use AppAnimal.Case, async: true
  alias Network.Timer, as: UT

  test "repeating" do
    pid = start_link_supervised!(UT)

    assert :ok == UT.begin_throbbing(pid, every: 10, notify: self())

    assert_receive_cast(:time_to_throb)
    assert_receive_cast(:time_to_throb)
    assert_receive_cast(:time_to_throb)
  end

  test "one_shot" do
    pid = start_link_supervised!(UT)

    assert :ok == UT.cast(pid, "payload", after: 10)

    assert_receive({:"$gen_cast", "payload"})
    refute_receive(_)
  end
end
