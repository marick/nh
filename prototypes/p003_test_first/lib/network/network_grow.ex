alias AppAnimal.Network

defmodule Network.Grow do
  use AppAnimal
  use KeyConceptAliases

  def unordered(%Network{} = s_network, clusters) do
    reducer =
      fn
        name, acc when is_atom(name) ->
          unless existing_name?(acc, name) do
            msg = "You referred to `#{inspect name}`, but there is no such cluster"
            raise KeyError, msg
          end
          acc
        cluster, acc ->
          acc
          |> add_cluster(cluster)
          |> add_to_name_set(cluster)
          |> add_to_id_map(cluster)
      end

    Enum.reduce(clusters, s_network, reducer)
  end

  def cluster(%Network{} = s_network, cluster),
      do: unordered(s_network, [cluster])

  def trace(%Network{} = s_network, clusters, opts \\ []) do
    [pulse_type] = Opts.parse(opts, for_pulse_type: :default)
    s_network
    |> unordered(clusters)
    |> add_sequence_of_targets(clusters, pulse_type)
  end

  def fan_out(%Network{} = s_network, opts) do
      [from, destinations, for_pulse_type] =
        Opts.parse(opts, [:from, :to, for_pulse_type: :default])

    s_network
    |> unordered([from | destinations])
    |> add_direct_targets(from, destinations, for_pulse_type)
  end

  def install_routers(%Network{} = s_network, router) do
    Network.CircularSubnet.call(s_network.p_circular_clusters, :add_router_to_all, router)

    lens = Lens.key(:linear_clusters) |> Network.LinearSubnet.routers()
    A.put(s_network, lens, router)
  end

  private do

    # parts

    def add_cluster(s_network, cluster) do
      name = cluster.name
      if existing_name?(s_network, name) do
        msg = "You attempted to add cluster `#{inspect name}`, which already exists"
        raise KeyError, msg
      end

      case cluster do
        %Cluster.Circular{} = _ ->
          pid = s_network.p_circular_clusters
          Network.CircularSubnet.call(pid, :add_cluster, cluster)
          s_network
        %Cluster.Linear{} = _ ->
          lens = Network.linear_clusters() |> Network.LinearSubnet.cluster_named(cluster.name)
          A.put(s_network, lens, cluster)
      end
    end

    def add_to_name_set(s_network, %Cluster.Circular{} = cluster) do
      Map.update!(s_network, :circular_names, & MapSet.put(&1, cluster.name))
    end

    def add_to_name_set(s_network, %Cluster.Linear{} = cluster) do
      Map.update!(s_network, :linear_names, & MapSet.put(&1, cluster.name))
    end

    #

    def add_to_id_map(s_network, cluster) when is_struct(cluster) do
      A.put(s_network, Network.name_to_id() |> Lens.key(cluster.name), cluster.id)
    end

    #

    def names_from(clusters) do
      mapper =
        fn
          atom when is_atom(atom) ->
            atom
          cluster ->
            cluster.name
        end
      Enum.map(clusters, mapper)
    end

    #

    def add_out_edge_values(out_edges, [], _pulse_type), do: out_edges

    def add_out_edge_values(out_edges, [[upstream, downstream] | rest], pulse_type) do
      out_edges
      |> update_in([upstream, pulse_type], fn mapset ->
        MapSet.put(mapset, downstream)
      end)
      |> add_out_edge_values(rest, pulse_type)
    end

    def add_sequence_of_targets(%Network{} = s_network, clusters, pulse_type) do
      names = names_from(clusters)

      mutated =
        s_network.out_edges
        |> Extras.Lens.ensure_nested_map_leaves([names, pulse_type], MapSet.new)
        |> add_out_edge_values(Enum.chunk_every(names, 2, 1, :discard), pulse_type)
      %{s_network | out_edges: mutated}
    end

    def add_direct_targets(s_network, from, destinations, pulse_type) do
      [from_name | destination_names] = names_from([from | destinations])
      mutated =
        s_network.out_edges
        |> Extras.Lens.ensure_nested_map_leaves([from_name, pulse_type], MapSet.new)
        |> update_in([from_name, pulse_type], &MapSet.union(&1, MapSet.new(destination_names)))
      %{s_network | out_edges: mutated}
    end

    #

    def existing_name?(s_network, name) do
      MapSet.member?(s_network.circular_names, name) ||
        MapSet.member?(s_network.linear_names, name)
    end
  end
end
