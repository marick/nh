alias AppAnimal.Network

defmodule Network.TimerTest do
  use ExUnit.Case, async: true
  alias Network.Timer, as: UT

  test "repeating" do
    pid = start_link_supervised!(UT)

    assert :ok == UT.cast(pid, "payload", every: 10, to: self())

    assert_receive({:"$gen_cast", "payload"})
    assert_receive({:"$gen_cast", "payload"})
    assert_receive({:"$gen_cast", "payload"})
  end

  test "one_shot" do
    pid = start_link_supervised!(UT)

    assert :ok == UT.cast(pid, "payload", after: 10)

    assert_receive({:"$gen_cast", "payload"})
    refute_receive(_)
  end
end
