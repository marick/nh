alias AppAnimal.Cluster
alias Cluster.CircularProcess

defmodule CircularProcess.TimerLogic do
  use TypedStruct
  
  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :current_strength, integer
    field :starting_strength, integer
  end

  def new(start_at), do: %__MODULE__{current_strength: start_at, starting_strength: start_at}

end

defmodule CircularProcess.State do
  alias CircularProcess.TimerLogic
  use AppAnimal
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :timer_logic, CircularProcess.TimerLogic.t
    field :shape, Cluster.Shape.t
    field :calc, fun
    field :f_outward, fun
    field :pulse_logic, Cluster.PulseLogic.t
    field :previously, any
  end
    
  def from_cluster(s_cluster) do
    timer = TimerLogic.new(s_cluster.shape.starting_pulses)

    %__MODULE__{shape: s_cluster.shape,
                calc: s_cluster.calc,
                f_outward: s_cluster.f_outward,
                pulse_logic: s_cluster.pulse_logic,
                timer_logic: timer,
                previously: s_cluster.shape.initial_value
  }
  end

  deflens l_current_strength(), do: in_timer(:current_strength)
  deflens l_starting_strength(), do: in_timer(:starting_strength)
  
  private do
    def in_timer(key), do: l_timer_logic() |> Lens.key(key)
  end
end

defmodule CircularProcess do
  use AppAnimal
  use AppAnimal.GenServer
  alias Cluster.Calc

  def init(starting_state) do
    ok(starting_state)
  end

  def handle_cast([handle_pulse: small_data], s_state) do
    result = Calc.run(s_state.calc, on: small_data, with_state: s_state.previously)

    Calc.maybe_pulse(result, & Cluster.start_pulse_on_its_way(s_state, &1))
    
    s_state
    |> deeply_put(:l_previously, Calc.next_state(result))
    |> continue
  end

  def handle_cast([weaken: n], s_state) do
    new_state = deeply_map(s_state, :l_current_strength, & &1-n)

    if deeply_get_only(new_state, :l_current_strength) <= 0,
       do: stop(new_state),
       else: continue(new_state)
  end
end
