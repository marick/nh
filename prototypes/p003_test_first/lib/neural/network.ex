defmodule AppAnimal.Neural.Network do
  use AppAnimal
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :clusters_by_name, %{atom => Cluster.t}, default: %{}
    field :throbbers_by_name, %{atom => pid}, default: %{}
  end

  deflens l_clusters,
          do: l_clusters_by_name() |> Lens.map_values()
  
  deflens l_cluster_named(name),
          do: l_clusters_by_name() |> Lens.key!(name)

  deflens l_downstream_of(name),
          do: l_cluster_named(name) |> Lens.key!(:downstream)

  deflens l_irrelevant_names,
          do: l_clusters() |> Cluster.l_never_throbs |> Lens.key!(:name)

  def new(cluster_map_or_keyword) do
    %__MODULE__{clusters_by_name: cluster_map_or_keyword |> Enum.into(%{})}
  end

  # Getters

  def throbbing_names(network), do: Map.keys(network.throbbers_by_name)
  def throbbing_pids(network), do: Map.values(network.throbbers_by_name)

  def throbbing_clusters(network) do
    throbbing_names(network)
    |> Enum.map(& network.clusters_by_name[&1])
  end

  # Working with clusters

  def start_throbbing(network, names) do
    to_start = needs_to_be_started(network, names)
     
    now_started =
      for cluster <- to_start, into: %{} do
        Cluster.start_throbbing(cluster)
      end
    deeply_map(network, :l_throbbers_by_name, & Map.merge(&1, now_started))
  end

  def drop_idling_pid(network, pid) do
    throbbers = network.throbbers_by_name
    
    [{name, _pid}] = 
      throbbers
      |> Enum.filter(fn {_name, value} -> value == pid end)

    %{network | throbbers_by_name: Map.drop(throbbers, [name])}
  end

  def deliver_pulse(network, names, pulse_data) do
    alias Cluster.Shape
    
    all_throbbing = start_throbbing(network, names)
    for name <- names do
      cluster = all_throbbing.clusters_by_name[name]
      case cluster.shape do
        %Shape.Circular{} ->
          p_process = all_throbbing.throbbers_by_name[name]
          send_pulse_into_genserver(p_process, pulse_data)
        %Shape.Linear{} ->
          send_pulse_into_task(cluster, pulse_data)
      end
    end
    all_throbbing
  end

  def send_pulse_into_genserver(pid, pulse_data) do
    GenServer.cast(pid, [handle_pulse: pulse_data])
  end

  def send_pulse_into_task(s_cluster, pulse_data) do
    alias Cluster.Calc
    
    Task.start(fn ->
      Calc.run(s_cluster.calc, on: pulse_data)
      |> Calc.maybe_pulse(& Cluster.start_pulse_on_its_way(s_cluster, &1))
      :there_is_no_return_value
    end)
  end

  def time_to_throb(network) do
    for {_name, pid} <- network.throbbers_by_name do
      GenServer.cast(pid, [weaken: 1])
    end
    :no_return_value
  end

  private do 
    def needs_to_be_started(network, names) do
      nameset = MapSet.new(names)
      ignore_irrelevant = deeply_get_all(network, l_irrelevant_names()) |> MapSet.new
      ignore_already = Map.keys(network.throbbers_by_name) |> MapSet.new
      
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

  def link_clusters_to_architecture(network,  p_switchboard, p_affordances) do
    mkfn_final =
      fn so_far ->
        case so_far do
          {:internal, f_maker} ->
            f_maker.(p_switchboard)
          {:external, f_maker} ->
            f_maker.(p_affordances)
          already_made when is_function(already_made, 1) ->
            already_made
        end
      end

    l_f_outward = l_clusters() |> Cluster.l_f_outward()
    
    deeply_map(network, l_f_outward, mkfn_final)
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
