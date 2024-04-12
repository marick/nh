alias AppAnimal.System
alias System.Network

defmodule Network do
  @moduledoc """
  The structure that represents the static structure of clusters and the connections
  between them. Also has the responsibility for delivering a pulse to a set of clusters.

  There are two types of clusters: circular (gensyms) and linear
  (tasks). "Delivering a cluster" works rather differently for each, so this module
  tries to hide that.

  A linear cluster is just wrapped in a Task and started. Purely asynchronous.

  A circular cluster has to be `start_linked` (a synchronous
  operation), then the pulse can be `cast` at it, which is the same
  sort of asynchronous action as starting a Task.

  """
  
  alias Network.Throb
  use AppAnimal
  use TypedStruct
  alias System.Pulse

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :clusters_by_name, %{atom => Cluster.t}, default: %{}
    field :throbbers_by_name, %{atom => pid}, default: %{}
    field :p_circular_clusters, pid, required: true
  end

  @doc false
  deflens l_clusters,
          do: l_clusters_by_name() |> Lens.map_values()
  
  @doc false
  deflens l_cluster_named(name),
          do: l_clusters_by_name() |> Lens.key!(name)

  @doc false
  deflens l_downstream_of(name),
          do: l_cluster_named(name) |> Lens.key!(:downstream)

  @doc false
  deflens l_irrelevant_names,
          do: l_clusters() |> Cluster.l_never_throbs |> Lens.key!(:name)

  def new(cluster_map_or_keywords) do
    clusters = cluster_map_or_keywords |> Enum.into(%{})
    {:ok, p_circular_clusters} = GenServer.start_link(Network.CircularClusters, [])
    %__MODULE__{clusters_by_name: clusters, p_circular_clusters: p_circular_clusters}
  end

  def put_routers(network, %System.Router{} = router) do
    l_router = l_clusters() |> Cluster.l_router()
    
    deeply_put(network, l_router, router)
  end

  def name_to_pid(network, name) do
    deeply_get_only(network, l_throbbers_by_name() |> Lens.key!(name))
  end

  def get_from_cluster(network, circular_cluster_name, getter_name) do
    pid = Network.name_to_pid(network, circular_cluster_name)
    GenServer.call(pid, getter_name)
  end

  @doc """
  Send a pulse to a mixture of "throbbing" and linear
  clusters.

  Throbbing clusters are what are elsewhere called "circular"
  clusters, here called that to emphasize that they receive timer
  pulses. (Possibly a bad naming.)

  A linear cluster is always ready to asynchronously accept a pulse
  and act on it. Easy peasy.

  A circular cluster may already be throbbing away, in which case the
  pulse is just `cast` in its direction. If not, it has to be started before the
  pulse can be `cast` at it.

  Yeah, this naming is not great.  
  """
  def deliver_pulse(network, names, %Pulse{} = pulse) do
    alias Cluster.Shape

    {circular_names, linear_names} = 
      Enum.split_with(names, fn name ->
        (network.clusters_by_name[name].shape.__struct__ == Shape.Circular)
      end)
    
    all_throbbing = Throb.start_throbbing(network, circular_names)
    
    for name <- circular_names do
      p_process = all_throbbing.throbbers_by_name[name]
      send_pulse_into_genserver(p_process, pulse)
    end
    
    for name <- linear_names do
      cluster = all_throbbing.clusters_by_name[name]
      send_pulse_into_task(cluster, pulse)
    end
    all_throbbing
  end

  private do 
    def send_pulse_into_genserver(pid, %Pulse{} = pulse) do
      GenServer.cast(pid, [handle_pulse: pulse])
    end
    
    def send_pulse_into_task(s_cluster, pulse) do
      alias Cluster.Calc

      Task.start(fn ->
        Calc.run(s_cluster.calc, on: pulse)
        |> Calc.maybe_pulse(& Cluster.start_pulse_on_its_way(s_cluster, &1))
        :there_is_no_return_value
      end)
    end
  end
end