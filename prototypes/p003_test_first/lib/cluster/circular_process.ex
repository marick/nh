alias AppAnimal.Cluster
alias Cluster.CircularProcess

defmodule CircularProcess.TimerLogic do
  defstruct [:current_strength, :starting_strength]

  def new(start_at), do: %__MODULE__{current_strength: start_at, starting_strength: start_at}
end

defmodule CircularProcess.State do
  defstruct [:timer_logic, :shape, :calc, :pulse_logic, :previously]

  def from_cluster(cluster) do
    timer = CircularProcess.TimerLogic.new(cluster.shape.starting_pulses)

    %__MODULE__{shape: cluster.shape,
                calc: cluster.calc,
                pulse_logic: cluster.pulse_logic,
                timer_logic: timer,
                previously: cluster.shape.initial_value
  }
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

  def handle_cast([weaken: _n], _state) do
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
