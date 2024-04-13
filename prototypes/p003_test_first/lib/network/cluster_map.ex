alias AppAnimal.Network

defmodule Network.ClusterMap do
  @moduledoc """
  Functions for, first, creating a `Network` and, next, linking all the
  clusters in the network into the larger `AppAnimal`, which will then
  `enliven` them.
  """
  use AppAnimal
  
  def trace(cluster_map \\ %{}, clusters) do
    cluster_map
    |> add_only_new_clusters(clusters)
    |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
  end

  def extend(cluster_map, at: name, with: trace) do
    existing = cluster_map[name]
    trace(cluster_map, [existing | trace])
  end

  private do 
    def add_only_new_clusters(cluster_map, trace) when is_list trace do
      Enum.reduce(trace, cluster_map, fn cluster, acc ->
        Map.put_new(acc, cluster.name, cluster)
      end)
    end
    
    def add_downstream(cluster_map, []), do: cluster_map
    
    def add_downstream(cluster_map, [[upstream, downstream] | rest]) do
      cluster_map
      |> update_in([upstream.name, Access.key(:downstream)], &([downstream.name | &1]))
      |> add_downstream(rest)
    end
  end
end
