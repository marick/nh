alias AppAnimal.Network

defmodule Network.LinearSubnet do
  @moduledoc """
  Manage the subset of clusters that are `Cluster.Linear`.

  Mainly distributing pulses, which is done by wrapping the cluster's `calc`
  function in a `Task` and starting the task. No return value is awaited.
  """
  use AppAnimal
  use KeyConceptAliases
  use MoveableAliases

  typedstruct enforce: true do
    field :name_to_cluster, %{atom => Cluster.t}
  end

  deflens routers,
          do: Lens.key(:name_to_cluster) |> Lens.map_values() |> Cluster.Linear.router()
  deflens cluster_named(name),
          do: Lens.key(:name_to_cluster) |> Lens.key(name)

  def new(clusters) do
    cluster_map =
      for c <- clusters, into: %{}, do: {c.name, c}
    %__MODULE__{name_to_cluster: cluster_map}
  end

  def fan_out(%__MODULE__{} = s_subnet, pulse, to: names) do
    for name <- names do
      s_subnet.name_to_cluster[name]
      |> send_pulse_into_task(pulse)
    end
  end

  def send_pulse_into_task(s_cluster, %Pulse{} = pulse) do
    alias Cluster.Calc

    Task.start(fn ->
      Calc.run(s_cluster.calc, on: pulse)
      |> Calc.cast_useful_result(s_cluster)
      :there_is_no_return_value
    end)
  end
end
