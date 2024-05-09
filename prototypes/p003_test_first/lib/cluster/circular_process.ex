alias AppAnimal.Cluster

defmodule Cluster.CircularProcess do
  use AppAnimal
  use AppAnimal.StructServer
  use KeyConceptAliases
  alias Cluster.Calc
  alias System.Pulse

  def start_link(cluster), do: GenServer.start_link(__MODULE__, cluster)


  @impl GenServer
  def init(%Cluster.Circular{} = starting_state) do
    ok(starting_state)
  end


  def handle_cast([handle_pulse: %Pulse{type: :suppress}], s_process_state) do
    s_process_state.throb.f_before_stopping.(s_process_state, s_process_state.previously)
    stop(s_process_state)
  end

  def handle_cast([handle_pulse: %Pulse{} = pulse], s_process_state) do
    result = Calc.run(s_process_state.calc,
                      on: pulse,
                      with_state: s_process_state.previously)

    Calc.cast_useful_result(result, s_process_state)

    s_process_state
    |> A.put(:previously, Calc.just_next_state(result))
    |> Map.update!(:throb, &Cluster.Throb.note_pulse(&1, result))
    |> continue
  end

  @impl GenServer
  def handle_cast([throb: n], s_process_state) do
    {action, next_throb} = Cluster.Throb.throb(s_process_state.throb, n)

    next_process_state = Map.put(s_process_state, :throb, next_throb)
    case action do
      :continue ->
        continue(next_process_state)
      :stop ->
        s_process_state.throb.f_before_stopping.(s_process_state, s_process_state.previously)
        stop(next_process_state)
    end
  end

  # Test support

  @impl GenServer
  def handle_call(:current_age, _from, s_process_state) do
    lifespan = A.get_only(s_process_state, :current_age)
    continue(s_process_state, returning: lifespan)
  end
end
