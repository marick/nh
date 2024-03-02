defmodule AppAnimal.Neural.NetworkBuilderTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Neural
  alias Neural.NetworkBuilder, as: UT
  import Neural.ClusterMakers
  use FlowAssertions

  def named(names) when is_list(names),
      do: Enum.map(names, &named/1)
  def named(name),
      do: circular_cluster(name, fn _, _ -> :irrelevant end)

  def downstreams(cluster_map) do
    Enum.reduce(cluster_map, %{}, fn {name, cluster}, acc ->
      Map.put(acc, name, cluster.downstream)
    end)
  end

  def assert_connections(network, field_descriptions) do
    network
    |> downstreams
    |> assert_fields(field_descriptions)
  end
  
  describe "building a network" do
    test "singleton" do
      first = named(:first)
      assert UT.independent([first]) == %{first: first}
    end
    
    test "multiple clusters in a row (a 'trace')" do
      named([:first, :second, :third])
      |> UT.independent
      |> assert_connections(first: [:second], second: [:third])
    end

    test "note that it's allowable to add duplicates, making traces loopy" do
      [first, second, third] = named([:first, :second, :third])

      [first, second, first, third, second]
      |> UT.independent
      |> assert_connections(first: in_any_order([:second, :third]),
                            second: [:first],
                            third: [:second])
    end

    test "can build from multiple disjoint traces" do
         UT.independent(named([:a1, :a2]))
      |> UT.independent(named([:b1, :b2]))
      |> assert_connections(a1: [:a2], a2: [],
                            b1: [:b2], b2: [])
    end

    test "can add a branch starting at an existing node" do
      UT.independent(named([:first,              :second_a, :third]))
      |> UT.extend(     at: :first, with: named([:second_b, :third]))
      |> assert_connections(first: in_any_order([:second_a, :second_b]),
                            second_a: [:third],
                            second_b: [:third])
    end
  end

  describe "helpers" do 
    test "put_new" do
      UT.put_new(%{}, [%{name: 1}, %{name: 2}])
      |> assert_equals(%{1 => %{name: 1}, 2 => %{name: 2}})
    end
    
    test "add_downstream" do
      trace = [first, second, third] = Enum.map([:first, :second, :third], &named/1)
      
      network =
        UT.put_new(%{}, trace)
        |> UT.add_downstream([[first, second], [second, third]])
      
      assert network.first.downstream == [:second]
      assert network.second.downstream == [:third]
      assert network.third.downstream == []
    end
  end
end
