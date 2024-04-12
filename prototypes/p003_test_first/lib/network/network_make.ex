alias AppAnimal.System
alias System.Network

defmodule Network.Make do
  @moduledoc """
  Functions for, first, creating a `Network` and, next, linking all the
  clusters in the network into the larger `AppAnimal`, which will then
  `enliven` them.
  """
  use AppAnimal
  
  def trace(network \\ %Network{}, clusters) do
    old = network.clusters_by_name
    new = 
      add_only_new_clusters(old, clusters)
      |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
    %{network | clusters_by_name: new}
  end

  def extend(network, at: name, with: trace) do
    existing = deeply_get_only(network, Network.l_cluster_named(name))
    trace(network, [existing | trace])
  end

  private do 
    # I don't use lenses for this because it's too fiddly and non-obvious
    # how getting the priority right works.
    def add_only_new_clusters(network, trace) when is_list trace do
      Enum.reduce(trace, network, fn cluster, acc ->
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
end
