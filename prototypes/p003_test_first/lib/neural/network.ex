defmodule AppAnimal.Neural.Network do
  use AppAnimal
  use TypedStruct
  import Lens.Macros

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :clusters_by_name, %{atom => Cluster.t}, default: %{}
    field :active_by_name, %{atom => pid}, default: %{}
  end

  deflens l_cluster_named(name),
          do: l_clusters_by_name() |> Lens.key!(name)

  deflens l_downstream_of(name),
          do: l_cluster_named(name) |> Lens.key!(:downstream)

  deflens l_irrelevant_names do
    l_clusters_by_name() |> Lens.map_values |> Cluster.l_never_active |> Lens.key!(:name)
  end

  deflens l_pulse_logic,
          do: l_clusters_by_name() |> Lens.map_values() |> Lens.key!(:pulse_logic)

  def new(cluster_map_or_keyword) do
    %__MODULE__{clusters_by_name: cluster_map_or_keyword |> Enum.into(%{})}
  end

  # Getters

  def active_names(network), do: Map.keys(network.active_by_name)
  def active_pids(network), do: Map.values(network.active_by_name)

  def active_clusters(network) do
    active_names(network)
    |> Enum.map(& network.clusters_by_name[&1])
  end

  # Working with clusters

  def activate(network, names) do
    to_start = needs_to_be_started(network, names)
    now_started =
      for cluster <- to_start, into: %{} do
        Cluster.activate(cluster)
      end
    deeply_map(network, :l_active_by_name, & Map.merge(&1, now_started))
  end

  def drop_active_pid(network, pid) do
    actives = network.active_by_name
    
    [{name, _pid}] = 
      actives
      |> Enum.filter(fn {_name, value} -> value == pid end)

    %{network | active_by_name: Map.drop(actives, [name])}
  end

  def deliver_pulse(network, names, pulse_data) do
    activated = activate(network, names)
    for name <- names do
      cluster = activated.clusters_by_name[name]
      pid = activated.active_by_name[name]
      Cluster.Shape.accept_pulse(cluster.shape, cluster, pid, pulse_data)
    end
    activated
  end

  def weaken_all_active(network) do
    for {_name, pid} <- network.active_by_name do
      GenServer.cast(pid, [weaken: 1])
    end
    :no_return_value
  end

  private do 
    def needs_to_be_started(network, names) do
      nameset = MapSet.new(names)
      ignore_irrelevant = deeply_get_all(network, l_irrelevant_names()) |> MapSet.new
      ignore_already = Map.keys(network.active_by_name) |> MapSet.new
      
      nameset
      |> MapSet.difference(ignore_irrelevant)
      |> MapSet.difference(ignore_already)
      |> Enum.map(& network.clusters_by_name[&1])
    end
  end

  ## Builders

  def trace(network \\ %__MODULE__{}, clusters) do
    old = network.clusters_by_name
    new = 
      add_only_new_clusters(old, clusters)
      |> add_downstream(Enum.chunk_every(clusters, 2, 1, :discard))
    %{network | clusters_by_name: new}
  end
  
  def extend(network, at: name, with: trace) do
    existing = deeply_get_only(network, l_cluster_named(name))
    trace(network, [existing | trace])
  end

  def individualize_pulses(network, switchboard_pid, affordances_pid) do
    deeply_map(network, :l_pulse_logic,
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
