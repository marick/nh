alias AppAnimal.Cluster
alias Cluster.CircularProcess

defmodule CircularProcess.State do
  @moduledoc """

  Those parts of a `Cluster` that are relevant to the operation of this gensym. Here are
  the fields that are new:
  
  - throb          - Controls the aging of this cluster and its eventual exit.
                     Initialized from Shape.Circular.max_age.
  - previously     - The part of the state the `calc` function can channged.
                     Initialized from Shape.Circular.initial_value.
  """
  use AppAnimal
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :name, atom, required: true   # This is useful for debugging
    field :throb, Cluster.Throb.t
    field :calc, fun
    field :f_outward, fun
    field :previously, any
  end
    
  def from_cluster(s_cluster) do
    %__MODULE__{name: s_cluster.name,
                calc: s_cluster.calc,
                f_outward: s_cluster.f_outward,
                throb: s_cluster.shape.throb,
                previously: s_cluster.shape.initial_value
  }
  end

  deflens l_current_age(), do: in_throb(:current_age)
  deflens l_max_age(), do: in_throb(:max_age)
  
  private do
    def in_throb(key), do: l_throb() |> Lens.key(key)
  end
end

defmodule CircularProcess do
  use AppAnimal
  use AppAnimal.GenServer
  alias Cluster.Calc

  def init(starting_state) do
    ok(starting_state)
  end

  def handle_cast([handle_pulse: pulse], s_process_state) do
    result = Calc.run(s_process_state.calc,
                      on: pulse,
                      with_state: s_process_state.previously)

    Calc.maybe_pulse(result, & Cluster.start_pulse_on_its_way(s_process_state, &1))
    
    s_process_state
    |> deeply_put(:l_previously, Calc.next_state(result))
    |> Map.update!(:throb, &Cluster.Throb.note_pulse(&1, result))
    |> continue
  end

  def handle_cast([throb: n], s_process_state) do
    {action, next_throb} = Cluster.Throb.throb(s_process_state.throb, n)

    next_process_state = Map.put(s_process_state, :throb, next_throb)
    case action do
      :continue ->
        AppAnimal.GenServer.continue(next_process_state)
      :stop ->
        s_process_state.throb.f_before_stopping.(s_process_state.f_outward,
                                                 s_process_state.previously)
        AppAnimal.GenServer.stop(next_process_state)
    end
  end

  # Test support

  def handle_call(:current_age, _from, s_process_state) do
    lifespan = deeply_get_only(s_process_state, :l_current_age)
    continue(s_process_state, returning: lifespan)
  end
end
