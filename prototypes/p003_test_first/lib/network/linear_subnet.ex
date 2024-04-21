alias AppAnimal.{Network,System,Cluster}

defmodule Network.LinearSubnet do
  use AppAnimal
  use TypedStruct
  alias System.Pulse

  typedstruct enforce: true do
    field :name_to_cluster, %{atom => Cluster.t}
  end

  deflens cluster_named(name), do: Lens.key(:name_to_cluster) |> Lens.key(name)

  def new(clusters) do
    cluster_map =
      for c <- clusters, into: %{}, do: {c.name, Cluster.Linear.new(c)}
    %__MODULE__{name_to_cluster: cluster_map}
  end

  def distribute_pulse(%__MODULE__{} = s_subnet, opts) do
    [pulse, names] = Opts.required!(opts, [:carrying, :to])
    for name <- names do
      s_subnet.name_to_cluster[name]
      |> send_pulse_into_task(pulse)
    end
  end

  def send_pulse_into_task(s_cluster, %Pulse{} = pulse) do
    alias Cluster.Calc

    Task.start(fn ->
      Calc.run(s_cluster.calc, on: pulse)
      |> Calc.maybe_pulse(& Cluster.start_pulse_on_its_way(s_cluster, &1))
      :there_is_no_return_value
    end)
  end
end
