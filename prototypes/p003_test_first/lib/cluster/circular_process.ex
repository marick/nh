alias AppAnimal.Cluster
alias Cluster.CircularProcess

defmodule CircularProcess.State do
  @moduledoc """

  Those parts of a `Cluster` that are relevant to the operation of this gensym. Here are
  the fields that are new:
  
  - throb_logic    - Controls the aging of this cluster and its eventual exit.
                     Initialized from Shape.Circular.starting_pulses.
  - previously     - The part of the state the `calc` function can channged.
                     Initialized from Shape.Circular.starting_pulses.
  """
  use AppAnimal
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :throb_logic, Cluster.ThrobLogic.t
    field :calc, fun
    field :f_outward, fun
    field :previously, any
  end
    
  def from_cluster(s_cluster) do
    throb_logic = Cluster.ThrobLogic.new(s_cluster.shape.starting_pulses)

    %__MODULE__{calc: s_cluster.calc,
                f_outward: s_cluster.f_outward,
                throb_logic: throb_logic,
                previously: s_cluster.shape.initial_value
  }
  end

  deflens l_current_strength(), do: in_throb_logic(:current_strength)
  deflens l_starting_strength(), do: in_throb_logic(:starting_strength)
  
  private do
    def in_throb_logic(key), do: l_throb_logic() |> Lens.key(key)
  end
end

defmodule CircularProcess do
  use AppAnimal
  use AppAnimal.GenServer
  alias Cluster.{Calc, ThrobLogic}

  def init(starting_state) do
    ok(starting_state)
  end

  def handle_cast([handle_pulse: small_data], s_state) do
    result = Calc.run(s_state.calc, on: small_data, with_state: s_state.previously)

    Calc.maybe_pulse(result, & Cluster.start_pulse_on_its_way(s_state, &1))
    
    s_state
    |> deeply_put(:l_previously, Calc.next_state(result))
    |> Map.update!(:throb_logic, &ThrobLogic.note_pulse(&1, result))
    |> continue
  end

  def handle_cast([throb: n], s_state) do
    {action, next_throb_logic} = ThrobLogic.throb(s_state.throb_logic, n)

    s_state
    |> Map.put(:throb_logic, next_throb_logic)
    |> then(& apply(AppAnimal.GenServer, action, [&1])) # this is really too cutesy.
  end
end
