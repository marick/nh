alias AppAnimal.{System,Network}

defmodule Network.CircularSubnetTest do
  use AppAnimal.Case, async: true
  alias Network.CircularSubnet, as: UT
  alias System.Pulse

  describe "construction of a throbber" do
    test "A throbber is initialized with a set of *circular* clusters" do
      original = C.circular(:will_throb)
      pid = start_link_supervised!(UT)
      UT.call__add_cluster(pid, original)

      assert [original] == UT.clusters(pid)
      assert [] == UT.throbbing_names(pid)
      assert [] == UT.throbbing_pids(pid)
    end
  end

  test "setting routers" do
    pid = start_link_supervised!(UT)
    UT.call__add_cluster(pid, C.circular(:first))
    UT.call__add_cluster(pid, C.circular(:second))

    UT.add_router_to_all(pid, "the new router")

    [one, other] = UT.clusters(pid)
    assert one.router == "the new router"
    assert other.router == "the new router"
  end

  @tag :test_uses_sleep
  test "the life cycle of a cluster, from the point of view of the network" do
    p_test = self()
    kludge_a_calc = fn arg ->
      send(p_test, {self(), arg})
      :no_result
    end

    p_ut = start_link_supervised!(UT)
    original = C.circular(:original, kludge_a_calc)
    unused = C.circular(:unused)
    UT.call__add_cluster(p_ut, original)
    UT.call__add_cluster(p_ut, unused)


    UT.cast__distribute_pulse(p_ut, carrying: Pulse.new("value"), to: [:original])
    assert {p_cluster, "value"} = assert_receive(_)

    # Another pulse goes to the same pid
    UT.cast__distribute_pulse(p_ut, carrying: Pulse.new("value"), to: [:original])
    assert {^p_cluster, "value"} = assert_receive(_)

    # A dead process removes it from the throbbing list.
    assert [p_cluster] == UT.throbbing_pids(p_ut)
    # :normal exits are swallowed by the process
    # https://hexdocs.pm/elixir/Process.html#exit/2
    Process.exit(p_cluster, :some_non_normal_value)
    Process.sleep(10)
    assert [] == UT.throbbing_pids(p_ut)
  end


  test "only :default pulses start a circular cluster" do
    kludge_a_calc = fn _arg ->
      raise "should never be called"
    end

    p_ut = start_link_supervised!(UT)
    original = C.circular(:original, kludge_a_calc)
    UT.call__add_cluster(p_ut, original)


    UT.cast__distribute_pulse(p_ut, carrying: Pulse.new(:oddity, "value"), to: [:original])
    refute_receive(_)

    assert [] == UT.throbbing_pids(p_ut)
  end
end
