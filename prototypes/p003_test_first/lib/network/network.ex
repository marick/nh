alias AppAnimal.{Network,Cluster}

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
  use MoveableAliases
  alias Network.{LinearSubnet,CircularSubnet}

  typedstruct do
    plugin TypedStructLens

    field :name_to_id, %{atom => Cluster.Identification.t}, default: %{}
    field :out_edges, %{atom => %{atom => MapSet.t(atom)}}, default: %{}

    field :circular_names, MapSet.t(atom),                  default: MapSet.new
    field :linear_names, MapSet.t(atom),                    default: MapSet.new

    field :p_circular_clusters, pid,                 enforce: true
    field :linear_clusters, LinearSubnet.t,  enforce: true
  end

  def empty() do
    {:ok, p_circular_clusters} = CircularSubnet.start_link([])

    struct!(__MODULE__, p_circular_clusters: p_circular_clusters,
                        linear_clusters: LinearSubnet.new([]))
  end

  def full_identification(network, name), do: Map.fetch!(network.name_to_id, name)

  def destination_names(network, from: source_name, for: pulse_type) when is_atom(pulse_type) do
    network.out_edges
    |> Map.fetch!(source_name)
    |> Map.fetch!(pulse_type)
  end

  def destination_names(network, from: source_name, for: pulse) when is_struct(pulse) do
    destination_names(network, from: source_name, for: pulse.type)
  end

  def router_for(network, name) do
    circular_case =
      if MapSet.member?(network.circular_names, name) do
        network.p_circular_clusters
        |> CircularSubnet.call(:router_for, name)
      end

    linear_case =
      if MapSet.member?(network.linear_names, name) do
        network.linear_clusters
        |> A.get_only(LinearSubnet.cluster_named(name))
        |> Map.get(:router)
      end

    circular_case || linear_case
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
    {circular_names, linear_names} =
      split_targets(network, names)

    CircularSubnet.cast(network.p_circular_clusters, :distribute_pulse,
                        carrying: pulse,
                        to: circular_names)
    LinearSubnet.distribute_pulse(network.linear_clusters,
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
