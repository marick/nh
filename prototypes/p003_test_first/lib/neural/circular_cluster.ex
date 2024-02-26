defmodule AppAnimal.Neural.CircularCluster do
  defstruct [:name, :handlers, downstream: [], send_pulse_downstream: :installed_by_switchboard]

  use GenServer

  def init(configuration) do
    {:ok, {configuration, configuration.handlers.initialize.(configuration)}}
  end

  def handle_cast([handle_pulse: small_data], {configuration, mutable}) do
    mutated =
      apply(configuration.handlers.pulse, [small_data, configuration, mutable])
    {:noreply, {configuration, mutated}}
  end
end
