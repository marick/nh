defmodule AppAnimal.Neural.CircularCluster do
  use GenServer

  defstruct [:name,
             :handlers,
             downstream: [],
             default_lifespan_in_seconds: 2,
             send_pulse_downstream: :installed_by_switchboard]

  def init(configuration) do
    specialized_state = configuration.handlers.initialize.(configuration)
    full_state = %{reinforcement_strength: configuration.default_lifespan_in_seconds * 10} |> Map.merge(specialized_state)
    {:ok, {configuration, full_state}}
  end

  def handle_cast([handle_pulse: small_data], {configuration, mutable}) do
    mutated =
      apply(configuration.handlers.pulse, [small_data, configuration, mutable])
    {:noreply, {configuration, mutated}}
  end

  def handle_cast([weaken: n], {configuration, mutable}) do
    new_lifespan = mutable.reinforcement_strength - n
    mutated = Map.put(mutable, :reinforcement_strength, new_lifespan)
    
    new_state = {configuration, mutated}
    
    if new_lifespan <= 0 do
      {:stop, :normal, new_state}
    else
      {:noreply, new_state}
    end
  end
end
