alias AppAnimal.Building

defmodule Building.Whole.ProcessTest do
  use ClusterCase, async: true
  alias Building.Whole.Process, as: UT
  alias Building.Parts, as: P

  test "beginning" do
    m = start_link_supervised!(UT)
    # This test is allowed to peek into the bugs
    %{linear_clusters: linears, p_circular_clusters: p_circular} = network = UT.network(m)

    assert_fields(network, name_to_id: %{},
                           downstreams_by_name: %{},
                           circular_names: MapSet.new,
                           linear_names: MapSet.new)
    assert is_pid(p_circular)
    assert linears.name_to_cluster == %{}
  end

  describe "adding clusters" do
    test "unordered circular clusters" do
      m = start_link_supervised!(UT)
      first = P.circular(:first)
      second = P.circular(:second)

      UT.unordered(m, [first, second])

      network = UT.network(m)

      Network.CircularSubnet.clusters(network.p_circular_clusters)
      |> assert_good_enough(in_any_order([first, second]))

      assert network.circular_names == MapSet.new([:first, :second])

      network.name_to_id
      |> assert_fields(first: first.id, second: second.id)

      # Does not change downstream relationships
      assert network.downstreams_by_name == %{}
    end

    test "traces also update 'downstream' relationships" do
      m = start_link_supervised!(UT)
      first = P.circular(:first)
      second = P.circular(:second)

      UT.trace(m, [first, second])

      network = UT.network(m)

      # spot check that `trace` uses `unordered`
      assert network.circular_names == MapSet.new([:first, :second])

      # downstream
      assert Network.downstream_of(network, :first) == MapSet.new([:second])
      assert Network.downstream_of(network, :second) == MapSet.new([])
    end
  end
end

