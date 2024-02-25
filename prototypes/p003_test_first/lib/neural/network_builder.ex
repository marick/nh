defmodule AppAnimal.Neural.NetworkBuilder do
  alias AppAnimal.Neural

  def cluster(name, module, handle_pulse) do
    module.new(name, handle_pulse)
  end
                                          

  def circular_cluster(name, handle_pulse) do
    cluster(name, Neural.CircularCluster, handle_pulse)
  end

  def start(clusters) do
    add_trace(%{}, clusters)
  end

  def add_trace(network, clusters) do
    put_new(network, clusters)
    |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
  end

  def add_branch(network, clusters, at: name) do
    cluster = network[name]
    add_trace(network, [cluster | clusters])
  end

  def put_new(network, clusters) when is_list clusters do
    Enum.reduce(clusters, network, fn cluster, acc ->
      Map.put_new(acc, cluster.name, cluster)
    end)
  end

  def add_downstream(network, []), do: network

  def add_downstream(network, [[upstream, downstream] | rest]) do
    network 
    |> update_in([upstream.name, Access.key(:downstream)], &([downstream.name | &1]))
    |> add_downstream(rest)
  end
end
