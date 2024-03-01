defmodule AppAnimal.Neural.NetworkBuilder do
  use AppAnimal
  
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

  private do 

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
end
