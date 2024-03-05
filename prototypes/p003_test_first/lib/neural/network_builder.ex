defmodule AppAnimal.Neural.NetworkBuilder do
  use AppAnimal

  def trace(network \\ %{}, clusters) do
    put_new(network, clusters)
    |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
  end
  
  def extend(network, at: name, with: trace) do
    existing = network[name]
    trace(network, [existing | trace])
  end

  private do 

    def put_new(network, trace) when is_list trace do
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
