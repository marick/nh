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
    field :ids_by_name, %{atom => Cluster.Identification.t}, default: %{}
    field :downstreams_by_name, %{atom => MapSet.t(atom)}

    field :circular_names, MapSet.t(atom)
    field :p_circular_clusters, pid

    field :clusters_by_name, %{atom => Cluster.t}, default: %{}
    field :linear_names, MapSet.t(atom)
  end

  def new(%{} = cluster_map) do
    clusters = Map.values(cluster_map)
    {circular_clusters, linear_clusters}  =
      Enum.split_with(clusters, &Cluster.can_throb?/1)

    {:ok, p_circular_clusters} =
      Network.CircularSubnet.start_link(circular_clusters)

    ids_by_name =
      for c <- clusters, into: %{}, do: {c.name, Cluster.Identification.new(c)}

    downstreams_by_name =
      for c <- clusters, into: %{},
                         do: {c.name, MapSet.new(c.downstream)}
    
    %__MODULE__{clusters_by_name: cluster_map,
                p_circular_clusters: p_circular_clusters,
                ids_by_name: ids_by_name,
                downstreams_by_name: downstreams_by_name,
                circular_names: MapSet.new(for c <- circular_clusters, do: c.name),
                linear_names: MapSet.new(for c <- linear_clusters, do: c.name)
    }
  end

  def full_identification(network, name), do: Map.fetch!(network.ids_by_name, name)

  def downstream_of(network, name), do: Map.fetch!(network.downstreams_by_name, name)

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
      split_targets(network, names)

    Network.CircularSubnet.cast__distribute_pulse(network.p_circular_clusters,
                                                    carrying: pulse,
                                                    to: circular_names)
    for name <- linear_names do
      cluster = network.clusters_by_name[name]
      send_pulse_into_task(cluster, pulse)
    end
    :no_return_value
  end

  private do
    def split_targets(network, given) do 
      given_set = MapSet.new(given)

      {}
      |> Tuple.append(MapSet.intersection(network.circular_names, given_set))
      |> Tuple.append(MapSet.intersection(network.linear_names,   given_set))
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
