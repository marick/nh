alias AppAnimal.Cluster
alias Cluster.CircularProcess

defmodule CircularProcess.State do
  @moduledoc """

  Those parts of a `Cluster` that are relevant to the operation of this gensym. Here are
  the fields that are new:
  
  - throb          - Controls the aging of this cluster and its eventual exit.
                     Initialized from Shape.Circular.starting_lifespan.
  - previously     - The part of the state the `calc` function can channged.
                     Initialized from Shape.Circular.initial_value.
  """
  use AppAnimal
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :throb, Cluster.Throb.t
    field :calc, fun
    field :f_outward, fun
    field :previously, any
  end
    
  def from_cluster(s_cluster) do
    throb = Cluster.Throb.new(s_cluster.shape.starting_lifespan)

    %__MODULE__{calc: s_cluster.calc,
                f_outward: s_cluster.f_outward,
                throb: throb,
                previously: s_cluster.shape.initial_value
  }
  end

  deflens l_current_lifespan(), do: in_throb(:current_lifespan)
  deflens l_starting_lifespan(), do: in_throb(:starting_lifespan)
  
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

  def handle_cast([handle_pulse: small_data], s_process_state) do
    result = Calc.run(s_process_state.calc, on: small_data, with_state: s_process_state.previously)

    Calc.maybe_pulse(result, & Cluster.start_pulse_on_its_way(s_process_state, &1))
    
    s_process_state
    |> deeply_put(:l_previously, Calc.next_state(result))
    |> Map.update!(:throb, &Cluster.Throb.note_pulse(&1, result))
    |> continue
  end

  def handle_cast([throb: n], s_process_state) do
    {action, next_throb} = Cluster.Throb.throb(s_process_state.throb, n)

    s_process_state
    |> Map.put(:throb, next_throb)
    |> then(& apply(AppAnimal.GenServer, action, [&1])) # this is really too cutesy.
  end

  # Test support

  def handle_call(:current_lifespan, _from, s_process_state) do
    lifespan = deeply_get_only(s_process_state, :l_current_lifespan)
    continue(s_process_state, returning: lifespan) |> dbg
  end
end
