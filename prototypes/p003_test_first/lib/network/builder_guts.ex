alias AppAnimal.{Network,NetworkBuilder, Cluster}

defmodule NetworkBuilder.Guts do
  use AppAnimal

  def trace(%Network{} = s_network, clusters) do
    s_network
    |> unordered(clusters)
    |> add_to_downstreams(clusters)
  end

  def unordered(%Network{} = s_network, clusters) do
    Enum.reduce(clusters, s_network, fn cluster, acc ->
      acc
      |> add_cluster(cluster)
      |> add_to_name_set(cluster)
      |> add_to_id_map(cluster)
    end)
  end

  def add_to_downstreams(%Network{} = s_network, clusters) do
    names = names_from(clusters)
    mutated =
      s_network.name_to_downstreams
      |> downstream_ensure_keys(names)
      |> downstream_add_values(Enum.chunk_every(names, 2, 1, :discard))
    %{s_network | name_to_downstreams: mutated}
  end

  def install_routers(%Network{} = s_network, router) do
    Network.CircularSubnet.add_router_to_all(s_network.p_circular_clusters, router)

    lens = Lens.key(:linear_clusters) |> Network.LinearSubnet.routers()
    A.put(s_network, lens, router)
  end

  private do

    # parts

    def add_cluster(s_network, cluster) do
      name = cluster.name
      if MapSet.member?(s_network.circular_names, name) ||
           MapSet.member?(s_network.linear_names, name) do
        msg = "You attempted to add cluster `#{inspect name}`, which already exists"
        raise KeyError, msg
      end

      case cluster do
        %Cluster.Circular{} = _ ->
          pid = s_network.p_circular_clusters
          Network.CircularSubnet.call__add_cluster(pid, cluster)
          s_network
        %Cluster.Linear{} = _ ->
          lens = Network.linear_clusters() |> Network.LinearSubnet.cluster_named(cluster.name)
          A.put(s_network, lens, cluster)
      end
    end

    # def add_cluster(s_network, %Cluster.Circular{} = cluster) do
    #   pid = s_network.p_circular_clusters
    #   Network.CircularSubnet.call__add_cluster(pid, cluster)
    #   s_network
    # end

    # def add_cluster(s_network, %Cluster.Linear{} = cluster) do
    #   lens = Network.linear_clusters() |> Network.LinearSubnet.cluster_named(cluster.name)
    #   A.put(s_network, lens, cluster)
    # end

    #

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
      mapper = fn cluster -> cluster.name end
      Enum.map(clusters, mapper)
    end

    #

    def downstream_ensure_keys(name_to_names, upstream_names) do
      Enum.reduce(upstream_names, name_to_names, fn name, acc ->
        Map.put_new(acc, name, MapSet.new)
      end)
    end

    def downstream_add_values(name_to_names, []), do: name_to_names

    def downstream_add_values(name_to_names, [[upstream, downstream] | rest]) do
      name_to_names
      |> Map.update!(upstream, & MapSet.put(&1, downstream))
      |> downstream_add_values(rest)
    end
  end
end
