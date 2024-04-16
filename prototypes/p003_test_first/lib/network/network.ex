alias AppAnimal.{Network,System,Cluster}

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
  
  use AppAnimal
  use TypedStruct
  alias System.Pulse

  typedstruct enforce: true do
    field :clusters_by_name, %{atom => Cluster.t}, default: %{}
    field :throbbers_by_name, %{atom => pid}, default: %{}
    field :p_circular_clusters, pid
  end

  def new(%{} = cluster_map) do
    circular_clusters =
      Map.values(cluster_map)
      |> Enum.filter(&Cluster.can_throb?/1)

    {:ok, p_circular_clusters} =
      Network.CircularClusters.start_link(circular_clusters)
    %__MODULE__{clusters_by_name: cluster_map, p_circular_clusters: p_circular_clusters}
  end

  def full_identification(network, name),
      do: network.clusters_by_name[name] |> Cluster.Identification.new

  def downstream_of(network, name),
      do: network.clusters_by_name[name].downstream

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
    {circular_names, linear_names} = 
      Enum.split_with(names, fn name ->
        Cluster.can_throb?(network.clusters_by_name[name])
      end)

    Network.CircularClusters.cast__distribute_pulse(network.p_circular_clusters,
                                                    carrying: pulse,
                                                    to: circular_names)
    for name <- linear_names do
      cluster = network.clusters_by_name[name]
      send_pulse_into_task(cluster, pulse)
    end
    :no_return_value
  end

  private do 
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
