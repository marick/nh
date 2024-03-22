defmodule AppAnimal.System.NetworkTest do
  use ClusterCase, async: true
  alias System.Network, as: UT
  
  defp named(names) when is_list(names),
       do: Enum.map(names, &named/1)
  defp named(name),
       do: circular(name)

  defp downstreams(network) do
    for one <- deeply_get_all(network, :l_clusters), into: %{} do
      {one.name, one.downstream}
    end
  end
  
  defp assert_connections(network, field_descriptions) do
    network
    |> downstreams
    |> assert_fields(field_descriptions)
  end
  
  describe "lenses" do
    test "l_cluster_named" do 
      network = UT.new(first: "a cluster")
      assert deeply_get_only(network, UT.l_cluster_named(:first)) == "a cluster"
    end

    test "l_downstream_of" do
      network = UT.new(first: named(:first))
      assert deeply_get_only(network, UT.l_downstream_of(:first)) == []
    end
  end
  
  describe "building a network (basics)" do
    test "singleton" do
      first = linear(:first)
      assert UT.trace([first]).clusters_by_name.first == first
    end

    test "multiple clusters in a row (a 'trace')" do
      named([:first, :second, :third])
      |> UT.trace
      |> assert_connections(first: [:second], second: [:third])
    end

    test "can build from multiple disjoint traces" do
         UT.trace(named([:a1, :a2]))
      |> UT.trace(named([:b1, :b2]))
      |> assert_connections(a1: [:a2], a2: [],
                            b1: [:b2], b2: [])
    end
  end


  describe "handling of duplicates" do 
    test "new value does not overwrite an existing one" do
      first = linear(:first, & &1+1000)
      new_first = linear(:first, &Function.identity/1)
      network = UT.trace([first, new_first])
      assert network.clusters_by_name.first.calc == first.calc

      # Note that there's a loop because some version of first appears twice in the
      # trace.
      assert network.clusters_by_name.first.downstream == [:first]
    end

    test "adding duplicates doesn't overwrite the first cluster, but it makes traces loopy" do
      [first, second, third] = named([:first, :second, :third])

      [first, second, first, third, second]
      |> UT.trace
      |> assert_connections(first: in_any_order([:second, :third]),
                            second: [:first],
                            third: [:second])
    end

    test "can add a branch starting at an existing node" do
      # This is, in effect adding a duplicate
      UT.trace(named([      :first,              :second_a, :third]))
      |> UT.extend(     at: :first, with: named([:second_b, :third]))
      |> assert_connections(first: in_any_order([:second_a, :second_b]),
                            second_a: [:third],
                            second_b: [:third])
    end
  end

  describe "handling of throbbing clusters" do
    setup do
      [network: UT.trace([linear(:one_shot), circular(:idle), circular(:will_throb)])]
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
      |> UT.drop_idling_pid(pid)
      |> UT.throbbing_pids()
      |> assert_equals([])
    end
  end

  describe "helpers" do 
    test "add_only_new_clusters" do
      UT.add_only_new_clusters(%{}, [%{name: :one, value: "original"},
                                     %{name: :two},
                                     %{name: :one, value: "duplicate ignored"}])
      |> assert_equals(%{one: %{name: :one, value: "original"},
                         two: %{name: :two}})
    end
    
    test "add_only_new_clusters works when the duplicate comes in a different call" do
      original = %{one: %{name: :one, value: "original"}}
      UT.add_only_new_clusters(original, [ %{name: :two},
                                           %{name: :one, value: "duplicate ignored"}])
      |> assert_equals(%{one: %{name: :one, value: "original"},
                         two: %{name: :two}})
    end
    
    test "add_downstream" do
      trace = [first, second, third] = Enum.map([:first, :second, :third], &named/1)
      
      network =
        UT.add_only_new_clusters(%{}, trace)
        |> UT.add_downstream([[first, second], [second, third]])
      
      assert network.first.downstream == [:second]
      assert network.second.downstream == [:third]
      assert network.third.downstream == []
    end
  end
end
