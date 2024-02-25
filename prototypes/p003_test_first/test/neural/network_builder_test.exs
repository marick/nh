defmodule AppAnimal.Neural.NetworkBuilderTest do
  use ExUnit.Case, async: true
  alias AppAnimal.Neural.NetworkBuilder, as: UT
  use FlowAssertions

  def handle_pulse, do: fn _switchboard, _pulse_data -> :irrelevant end

  def some_cluster(name), do: UT.circular_cluster(name, handle_pulse())
  def clusters(names), do: Enum.map(names, &some_cluster/1)
  def downstreams(cluster_map) do
    Enum.reduce(cluster_map, %{}, fn {name, cluster}, acc ->
      Map.put(acc, name, cluster.downstream)
    end)
  end
  
  describe "building a network" do

    test "singleton" do
      first = some_cluster(:first)
      assert UT.start([first]) == %{first: first}
    end
    
    test "multiple clusters in a row" do
      clusters([:first, :second, :third])
      |> UT.start
      |> downstreams
      |> assert_fields(first: [:second], second: [:third])
    end

    test "note that it's allowable to add duplicates, making traces loopy" do
      [first, second, third] = clusters([:first, :second, :third])

      [first, second, first, third, second]
      |> UT.start
      |> downstreams
      |> assert_fields(first: in_any_order([:second, :third]),
                       second: [:first],
                       third: [:second])
    end

    test "can build from multiple disjoint traces" do
      clusters([:a1, :a2])
      |> UT.start
      |> UT.add_trace(clusters([:b1, :b2]))
      |> downstreams
      |> assert_fields(a1: [:a2], a2: [], b1: [:b2], b2: [])
    end

    test "can add a branch from an existing node" do
      clusters([:first, :second_a, :third])
      |> UT.start
      |> UT.add_branch(clusters([:second_b, :third]), at: :first)
      |> downstreams
      |> assert_fields(first: in_any_order([:second_a, :second_b]),
                       second_a: [:third],
                       second_b: [:third])
    end
  end

  test "put_new" do
    UT.put_new(%{}, [%{name: 1}, %{name: 2}])
    |> assert_equals(%{1 => %{name: 1}, 2 => %{name: 2}})
  end

  test "add_downstream" do
    clusters = [first, second, third] = Enum.map([:first, :second, :third], &some_cluster/1)

    network =
      UT.put_new(%{}, clusters)
      |> UT.add_downstream([[first, second], [second, third]])

    assert network.first.downstream == [:second]
    assert network.second.downstream == [:third]
    assert network.third.downstream == []
  end
end
