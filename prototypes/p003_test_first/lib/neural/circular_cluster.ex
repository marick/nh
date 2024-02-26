defmodule AppAnimal.Neural.CircularCluster do
  defstruct [:name, :handlers, downstream: [], send_pulse_downstream: :installed_by_switchboard]

  use GenServer

  def init(configuration) do
    specialized_state = configuration.handlers.initialize.(configuration)
    full_state = %{lifespan: 20} |> Map.merge(specialized_state)
    {:ok, {configuration, full_state}}
  end

  def handle_cast([handle_pulse: small_data], {configuration, mutable}) do
    mutated =
      apply(configuration.handlers.pulse, [small_data, configuration, mutable])
    {:noreply, {configuration, mutated}}
  end
end
