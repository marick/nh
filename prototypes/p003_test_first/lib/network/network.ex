alias AppAnimal.{Network,Cluster}

defmodule Network do
  @moduledoc """
  The structure that represents the static structure of clusters and the connections
  between them. Also has the responsibility for delivering a pulse to a set of clusters,
  though that responsibility is delegated to `LinearSubnet` and `CircularSubnet`.

  `AppAnimal.Network.Grow` contains functions that build the
  network. `AppAnimal.NetworkBuilder` is a process that coordinates
  the calls in a way convenient for writing scenario tests.
  """


  use AppAnimal
  use MoveableAliases
  alias Network.{LinearSubnet,CircularSubnet}

  # Certain fields cache values that are found in cluster structures. That's to avoid
  # reaching across process boundaries to get them. Less a matter of efficiency (I expect)
  # than of fidelity to the model of a real neural cluster.
  typedstruct enforce: true do
    plugin TypedStructLens

    field :p_circular_clusters, pid
    field :linear_clusters, LinearSubnet.t
    field :out_edges, %{atom => %{atom => MapSet.t(atom)}}, default: %{}

    # Caches
    field :name_to_id, %{atom => Cluster.Identification.t}, default: %{}
    field :linear_names, MapSet.t(atom),             default: MapSet.new
    field :circular_names, MapSet.t(atom),           default: MapSet.new
  end

  deflens id_for(name), do: name_to_id() |> Lens.key!(name)

  deflens downstream(opts) do
    [source_name, pulse_or_type] = Opts.parse(opts, [:from, for: :default])

    two_levels = out_edges() |> Lens.key(source_name)
    pulse_level =
      cond do
        is_struct(pulse_or_type, Moveable.Pulse) -> Lens.key!(pulse_or_type.type)
        is_atom(pulse_or_type) -> Lens.key!(pulse_or_type)
      end

    Lens.seq(two_levels, pulse_level)
  end

  def empty() do
    {:ok, p_circular_clusters} = CircularSubnet.start_link([])

    struct!(__MODULE__, p_circular_clusters: p_circular_clusters,
                        linear_clusters: LinearSubnet.new([]))
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
        |> A.one!(LinearSubnet.cluster_for(name))
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
  def fan_out(network, %Pulse{} = pulse, to: cluster_names) do
    {circular_names, linear_names} =
      split_targets(network, cluster_names)

    CircularSubnet.cast(network.p_circular_clusters,
                        :fan_out, pulse, to: circular_names)
    LinearSubnet.fan_out(network.linear_clusters,
                                  pulse, to: linear_names)
    @no_value
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
