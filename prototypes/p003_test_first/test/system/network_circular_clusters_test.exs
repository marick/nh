alias AppAnimal.{System,Cluster}
alias System.Network

defmodule Network.CircularClustersTest do
  use ClusterCase, async: true
  alias Network.CircularClusters, as: UT
  alias Cluster.CircularProcess
  alias System.Pulse

  describe "construction of a throbber" do 
  
    test "A throbber is initialized with a set of *circular* clusters" do

      original = circular(:will_throb)
      pid = start_link_supervised!({UT, [original]})
      
      assert [:will_throb] == UT.names(pid)
      assert [CircularProcess.State.from_cluster(original)] == UT.clusters(pid)
      assert [] == UT.throbbing_names(pid)
      assert [] == UT.throbbing_pids(pid)
    end
  end

  @tag :test_uses_sleep
  test "sending a pulse" do
    p_test = self()
    kludge_a_calc = fn arg ->
      send(p_test, {self(), arg})
      :no_result
    end

  
    original = circular(:original, kludge_a_calc)
    unused = circular(:unused)
    p_ut = start_link_supervised!({UT, [original, unused]})

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
  
  #   test "dropping pids from the list of ones throbbing", %{network: original} do
  #     # in response to such a pid going idle
  #     network = UT.start_throbbing(original, [:will_throb])
  #     assert [pid] = UT.throbbing_pids(network)

  #     network
  #     |> UT.pid_has_aged_out(pid)
  #     |> UT.throbbing_pids()
  #     |> assert_equals([])
  #   end
  # end
  
end
