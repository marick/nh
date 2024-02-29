defmodule AppAnimal.Neural.CircularCluster do
  use GenServer

  defstruct [:name,
             :handlers,
             downstream: [],
             starting_pulses: 20,
             send_pulse_downstream: :installed_by_switchboard]

  def init(configuration) do
    specialized_state = configuration.handlers.initialize.(configuration)
    full_state = %{reinforcement_strength: configuration.starting_pulses} |> Map.merge(specialized_state)
    {:ok, {configuration, full_state}}
  end

  def handle_cast([handle_pulse: small_data], {configuration, mutable}) do
    mutated =
      apply(configuration.handlers.pulse, [small_data, configuration, mutable])
    {:noreply, {configuration, mutated}}
  end

  def handle_cast([weaken: n], {configuration, mutable}) do
    mutated =
      Map.update!(mutable, :reinforcement_strength, &(&1 - n))
    
    new_state = {configuration, mutated}
    
    if mutated.reinforcement_strength <= 0 do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end
end
