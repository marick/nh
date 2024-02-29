defmodule AppAnimal.Extras.SplitState do
  def new_state(mutable, configuration) do
    {configuration, mutable}
  end

  def creating_mutable(configuration, f) when is_function(f, 0),
      do: f.()                       |> add_to_mutable(configuration)
  def mutating({configuration, mutable}, f) when is_function(f, 1),
      do: f.(mutable)                |> add_to_mutable(configuration)
  def mutating({configuration, mutable}, f) when is_function(f, 2),
      do: f.(mutable, configuration) |> add_to_mutable(configuration)

  def add_to_mutable(tuple_with_final_mutable, configuration) do
    last_index = tuple_size(tuple_with_final_mutable) - 1
    mutable = elem(tuple_with_final_mutable, last_index)
    tuple_with_final_mutable
    |> Tuple.delete_at(last_index)
    |> Tuple.insert_at(last_index, new_state(mutable, configuration))
  end
end

defmodule AppAnimal.Neural.CircularCluster do
  use AppAnimal
  use AppAnimal.GenServer
  import AppAnimal.Extras.SplitState

  defstruct [:name,
             :handlers,
             downstream: [],
             starting_pulses: 20,
             send_pulse_downstream: :installed_by_switchboard]

  def init(configuration) do
    creating_mutable(configuration, fn ->
      %{reinforcement_strength: configuration.starting_pulses}
      |> Map.merge(configuration.handlers.initialize.(configuration))
      |> ok()
    end)
  end

  def handle_cast([handle_pulse: small_data], state) do
    mutating(state, fn mutable, configuration ->
      configuration.handlers.pulse()
      |> apply([small_data, mutable, configuration])
      |> continue()
    end)
    
  end

  def handle_cast([weaken: n], state) do
    mutating(state, fn mutable ->
      mutated =
        Map.update!(mutable, :reinforcement_strength, &(&1 - n))
      if mutated.reinforcement_strength <= 0 do
        stop(mutated)
      else
        continue(mutated)
      end
    end)
  end
end
