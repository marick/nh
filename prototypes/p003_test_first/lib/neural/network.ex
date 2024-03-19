defmodule AppAnimal.Neural.Network do
  use AppAnimal
  use TypedStruct
  import Lens.Macros

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :clusters, %{atom => Cluster.t}, default: %{}
    field :active, %{atom => pid}, default: %{}
  end

  deflens l_cluster(name), do: l_clusters() |> Lens.key!(name)
  deflens l_downstream_of(name), do: l_cluster(name) |> Lens.key!(:downstream)
  deflens l_irrelevant_names, 
          do: l_clusters() |> Lens.map_values |> Cluster.l_never_active |> Lens.key!(:name)

  def new(cluster_map), do: %__MODULE__{clusters: cluster_map}

  # Getters

  def active_names(network), do: Map.keys(network.active)
  def active_pids(network), do: Map.values(network.active)

  def active_clusters(network) do
    active_names(network)
    |> Enum.map(& network.clusters[&1])
  end

  # Working with clusters

  def activate(network, names) do
    to_start = needs_to_be_started(network, names)
    now_started =
      for cluster <- to_start, into: %{} do
        Cluster.activate(cluster)
      end
    deeply_map(network, :l_active, & Map.merge(&1, now_started))
  end

  def drop_active_pid(network, pid) do
    actives = network.active
    
    [{name, _pid}] = 
      actives
      |> Enum.filter(fn {_name, value} -> value == pid end)

    %{network | active: Map.drop(actives, [name])}
  end

  def deliver_pulse(network, names, pulse_data) do
    activated = activate(network, names)
    for name <- names do
      cluster = activated.clusters[name]
      pid = activated.active[name]
      Cluster.Shape.accept_pulse(cluster.shape, cluster, pid, pulse_data)
    end
    activated
  end

  def weaken_all_active(network) do
    for {_name, pid} <- network.active do
      GenServer.cast(pid, [weaken: 1])
    end
    :no_return_value
  end

  private do 
    def needs_to_be_started(network, names) do
      nameset = MapSet.new(names)
      ignore_irrelevant = deeply_get_all(network, l_irrelevant_names()) |> MapSet.new
      ignore_already = Map.keys(network.active) |> MapSet.new
      
      nameset
      |> MapSet.difference(ignore_irrelevant)
      |> MapSet.difference(ignore_already)
      |> Enum.map(& network.clusters[&1])
    end
  end

  ## Builders

  def trace(network \\ %__MODULE__{}, clusters) do
    old = network.clusters
    new = 
      add_only_new_clusters(old, clusters)
      |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
    %{network | clusters: new}
  end
  
  def extend(network, at: name, with: trace) do
    existing = deeply_get_only(network, l_cluster(name))
    trace(network, [existing | trace])
  end

  def individualize_pulses(network, switchboard_pid, affordances_pid) do
    deeply_map(network, l_clusters() |> Lens.map_values() |> Lens.key!(:pulse_logic),
               & Cluster.PulseLogic.put_pid(&1, {switchboard_pid, affordances_pid}))
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
