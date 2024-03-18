defmodule AppAnimal.Neural.Network2 do
  use AppAnimal
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :_

    field :clusters, %{atom => Cluster.t}, default: %{}
    field :active, %{atom => pid}, default: %{}
  end

  def _cluster(name), do: _clusters() |> Lens.key!(name)

  def _downstream_of(name) do
    _cluster(name) |> Lens.key!(:downstream)
  end

  

  def trace(network \\ %__MODULE__{}, clusters) do
    old = network.clusters
    new = 
      add_only_new_clusters(old, clusters)
      |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
    %{network | clusters: new}
  end
  
  def extend(network, at: name, with: trace) do
    existing = deeply_get_only(network, _cluster(name))
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
