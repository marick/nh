alias AppAnimal.Cluster
alias Cluster.CircularProcess

defmodule CircularProcess.TimerLogic do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :_

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
    plugin TypedStructLens, prefix: :_

    field :timer_logic, CircularProcess.TimerLogic.t
    field :shape, Cluster.Shape.t
    field :calc, fun
    field :pulse_logic, Cluster.PulseLogic.t
    field :previously, any
  end
    
  def from_cluster(cluster) do
    timer = TimerLogic.new(cluster.shape.starting_pulses)

    %__MODULE__{shape: cluster.shape,
                calc: cluster.calc,
                pulse_logic: cluster.pulse_logic,
                timer_logic: timer,
                previously: cluster.shape.initial_value
  }
  end

  def _current_strength(), do: timer_seq(:current_strength)
  def _starting_strength(), do: timer_seq(:starting_strength)
  
  private do
    def timer_seq(key), do: Lens.seq(_timer_logic(), Lens.key(key))
  end
end

defmodule CircularProcess do
  use AppAnimal
  use AppAnimal.GenServer
  alias __MODULE__.State

  def init(starting_state) do
    ok(starting_state)
  end

  def handle_cast([handle_pulse: small_data], state) do
    case run_calculation(state, small_data) do
      {:ok, outgoing_pulse_data, next_previously} ->
        Cluster.PulseLogic.send_pulse(state.pulse_logic, outgoing_pulse_data)
        Map.put(state, :previously, next_previously)
        |> continue
    end
  end


  def handle_cast([weaken: n], state) do
    new_state = lens_update(state, :_current_strength, & &1-n)

    if lens_one!(new_state, :_current_strength) <= 0,
       do: stop(new_state),
       else: continue(new_state)
  end


  

  private do
    def run_calculation(%State{} = mutable, pulse_data) do
      result =
        case mutable.calc do
          f when is_function(f, 1) -> 
            f.(pulse_data)
          f when is_function(f, 2) ->
            f.(pulse_data, mutable.previously)
        end
      case result do
        {:ok, _, _} = verbatim ->
          verbatim
        _ -> 
          {:ok, result, mutable.previously}
      end
    end

    def update_state(state, {:ok, _outgoing_value}), do: state

    def update_state(state, {:ok, _outgoing_value, next_value_for_previously}),
        do: Map.put(state, :previously, next_value_for_previously)
  end
end
