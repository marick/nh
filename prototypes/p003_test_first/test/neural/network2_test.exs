defmodule AppAnimal.Neural.Network2Test do
  use ClusterCase, async: true
  alias Neural.Network2, as: UT
  
  defp named(names) when is_list(names),
       do: Enum.map(names, &named/1)
  defp named(name),
       do: circular(name)

  defp downstreams(network) do
    l_clusters = UT._clusters |> Lens.map_values

    for one <- deeply_get_all(network, l_clusters), into: %{} do
      {one.name, one.downstream}
    end
  end
  
  defp assert_connections(network, field_descriptions) do
    network
    |> downstreams
    |> assert_fields(field_descriptions)
  end
  
  describe "lenses" do
    test "_cluster" do 
      network = %UT{clusters: %{first: "a cluster"}}
      assert deeply_get_only(network, UT._cluster(:first)) == "a cluster"
    end

    test "_downstream_of" do
      network = %UT{clusters: %{first: named(:first)}}
      assert deeply_get_only(network, UT._downstream_of(:first)) == []
    end
  end
  
  describe "building a network (basics)" do
    test "singleton" do
      first = linear(:first)
      assert UT.trace([first]).clusters.first == first
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
      assert network.clusters.first.calc == first.calc

      # Note that there's a loop because some version of first appears twice in the
      # trace.
      assert network.clusters.first.downstream == [:first]
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

  describe "handling of active clusters" do
    setup do
      [network: UT.trace([linear(:one_shot), circular(:inactive), circular(:active)])]
    end

    test "originally nothing is active", %{network: network} do 
      assert UT.active_names(network) == []
      assert UT.active_pids(network) == []
      assert UT.active_clusters(network) == []
    end

    test "effect of one active cluster", %{network: original} do
      network = put_in(original.active, %{active: "some pid"})

      assert UT.active_names(network) == [:active]
      assert UT.active_pids(network) == ["some pid"]
      assert UT.active_clusters(network) == [circular(:active)]
    end

    test "determining which of a set of names should be ensured active", %{network: network} do
      assert UT.needs_to_be_started(network, [:one_shot]) == []

      
      assert [%Cluster{name: :inactive}]
             = UT.needs_to_be_started(network, [:one_shot, :inactive])

      # After an activation (faked here) there's no need to activate again
      assert [%Cluster{name: :inactive}] = 
               network
               |> Map.put(:active, %{active: "pid"})
               |> UT.needs_to_be_started([:one_shot, :inactive, :active])
    end

    test "let's do activation for real", %{network: original} do
      network = UT.activate(original, [:active])
      
      assert UT.active_names(network) == [:active]
      assert UT.active_clusters(network) == [circular(:active)]
 
      [pid] = UT.active_pids(network)
      assert is_pid(pid)
    end

    test "dropping active pids", %{network: original} do
      network = UT.activate(original, [:active])
      assert [pid] = UT.active_pids(network)

      network
      |> UT.drop_active_pid(pid)
      |> UT.active_pids()
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
