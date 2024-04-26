alias AppAnimal.{NetworkBuilder}

defmodule NetworkBuilderTest do
  use ClusterCase, async: true
  alias NetworkBuilder, as: UT

  test "beginning" do
    m = start_link_supervised!(UT)
    # This test is allowed to peek into the bugs
    %{linear_clusters: linears, p_circular_clusters: p_circular} = network = UT.network(m)

    assert_fields(network, name_to_id: %{},
                           name_to_downstreams: %{},
                           circular_names: MapSet.new,
                           linear_names: MapSet.new)
    assert is_pid(p_circular)
    assert linears.name_to_cluster == %{}
  end

  describe "adding clusters" do
    test "unordered circular clusters" do
      m = start_link_supervised!(UT)
      first = C.circular(:first)
      second = C.circular(:second)

      UT.unordered(m, [first, second])

      network = UT.network(m)

      Network.CircularSubnet.clusters(network.p_circular_clusters)
      |> assert_good_enough(in_any_order([first, second]))

      assert network.circular_names == MapSet.new([:first, :second])

      network.name_to_id
      |> assert_fields(first: first.id, second: second.id)

      # Does not change downstream relationships
      assert network.name_to_downstreams == %{}
    end

    test "traces also update 'downstream' relationships" do
      m = start_link_supervised!(UT)
      first = C.circular(:first)
      second = C.circular(:second)

      UT.trace(m, [first, second])

      network = UT.network(m)

      # spot check that `trace` uses `unordered`
      assert network.circular_names == MapSet.new([:first, :second])

      # downstream
      assert Network.downstream_of(network, :first) == MapSet.new([:second])
      assert Network.downstream_of(network, :second) == MapSet.new([])
    end

    test "linear clusters work too" do
      m = start_link_supervised!(UT)
      first = C.linear(:first)
      second = C.circular(:second)

      UT.trace(m, [first, second])

      network = UT.network(m)

      Network.CircularSubnet.clusters(network.p_circular_clusters)
      |> assert_equals([second])

      assert A.get_only(network.linear_clusters,
                        Network.LinearSubnet.cluster_named(:first)) == first

      assert network.circular_names == MapSet.new([:second])
      assert network.linear_names == MapSet.new([:first])

      network.name_to_id
      |> assert_fields(first: first.id, second: second.id)

      # downstream
      assert Network.downstream_of(network, :first) == MapSet.new([:second])
      assert Network.downstream_of(network, :second) == MapSet.new([])
    end
  end

  test "installing the routers" do
    m = start_link_supervised!(UT)
    first = C.linear(:first)
    second = C.circular(:second)

    UT.trace(m, [first, second])
    UT.install_routers(m, "this is a router")

    network = UT.network(m)
    Network.router_for(network, :first)
    assert Network.router_for(network, :first) == "this is a router"
    assert Network.router_for(network, :second) == "this is a router"
  end
end
