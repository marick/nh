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
    plugin TypedStructLens

    field :name_to_id, %{atom => Cluster.Identification.t}, default: %{}
    field :name_to_downstreams, %{atom => MapSet.t(atom)}

    field :circular_names, MapSet.t(atom)
    field :p_circular_clusters, pid

    field :linear_names, MapSet.t(atom)
    field :linear_clusters, Network.LinearSubnet.t
  end

  def empty(), do: new(%{})

  def new(%{} = cluster_map) do
    clusters = Map.values(cluster_map)
    {circular_clusters, linear_clusters}  =
      Enum.split_with(clusters, &Cluster.can_throb?/1)

    {:ok, p_circular_clusters} =
      Network.CircularSubnet.start_link(circular_clusters)

    name_to_id =
      for c <- clusters, into: %{}, do: {c.name, Cluster.Identification.new(c)}

    name_to_downstreams =
      for c <- clusters, into: %{},
                         do: {c.name, MapSet.new(c.downstream)}

    %__MODULE__{p_circular_clusters: p_circular_clusters,
                name_to_id: name_to_id,
                name_to_downstreams: name_to_downstreams,
                circular_names: MapSet.new(for c <- circular_clusters, do: c.name),
                linear_names: MapSet.new(for c <- linear_clusters, do: c.name),
                linear_clusters: Network.LinearSubnet.new(linear_clusters)
    }
  end

  def full_identification(network, name), do: Map.fetch!(network.name_to_id, name)

  def downstream_of(network, name), do: Map.fetch!(network.name_to_downstreams, name)

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
    Network.LinearSubnet.distribute_pulse(network.linear_clusters,
                                         carrying: pulse,
                                         to: linear_names)
    :no_return_value
  end

  private do
    def split_targets(network, given) do
      given_set = MapSet.new(given)

      {}
      |> Tuple.append(MapSet.intersection(network.circular_names, given_set))
      |> Tuple.append(MapSet.intersection(network.linear_names,   given_set))
    end
  end
end
