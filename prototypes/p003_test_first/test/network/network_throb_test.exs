alias AppAnimal.System.Network

defmodule Network.ThrobTest do
  use ClusterCase, async: true
  alias Network.Throb, as: UT


  describe "handling of throbbing clusters" do
    setup do
      [network: trace([linear(:one_shot), circular(:idle), circular(:will_throb)])]
    end

    test "originally nothing is throbbing", %{network: network} do 
      assert UT.throbbing_names(network) == []
      assert UT.throbbing_pids(network) == []
      assert UT.throbbing_clusters(network) == []
    end

    test "the effect of one throbbing cluster", %{network: original} do
      network = put_in(original.throbbers_by_name, %{will_throb: "some pid"})

      assert UT.throbbing_names(network) == [:will_throb]
      assert UT.throbbing_pids(network) == ["some pid"]
      assert UT.throbbing_clusters(network) == [circular(:will_throb)]
    end

    test "determining which of a set of names should be made to throb", %{network: network} do
      assert UT.needs_to_be_started(network, [:one_shot]) == []
      
      assert [%Cluster{name: :idle}]
             = UT.needs_to_be_started(network, [:one_shot, :idle])

      # After throbbing has started (faked here) there's no need to do it again
      assert [%Cluster{name: :idle}] = 
               network
               |> Map.put(:throbbers_by_name, %{will_throb: "pid"})
               |> UT.needs_to_be_started([:one_shot, :idle, :will_throb])
    end

    test "let's start throbbing for real", %{network: original} do
      network = UT.start_throbbing(original, [:will_throb])
      
      assert UT.throbbing_names(network) == [:will_throb]
      assert UT.throbbing_clusters(network) == [circular(:will_throb)]
 
      [pid] = UT.throbbing_pids(network)
      assert is_pid(pid)
    end

    test "dropping pids from the list of ones throbbing", %{network: original} do
      # in response to such a pid going idle
      network = UT.start_throbbing(original, [:will_throb])
      assert [pid] = UT.throbbing_pids(network)

      network
      |> UT.pid_has_aged_out(pid)
      |> UT.throbbing_pids()
      |> assert_equals([])
    end
  end

  
end
