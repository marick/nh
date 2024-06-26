alias AppAnimal.Cluster

defmodule Cluster.CircularProcess do
    @moduledoc """
    Define a process that manages `Cluster.Circular` state.
    """
  use AppAnimal
  use AppAnimal.StructServer
  use KeyConceptAliases
  alias Cluster.{Calc,Circular}
  alias Moveable.Pulse

  handle_CAST do
    # I still need to experiment with handling different types of
    # pulses. Some should be hardcoded for all circulars (like
    # `:suppress`), but I fear some may need to be handled in the
    # `calc` function, and oh no what if I need to override a default
    # hardcoded implementation?
    #
    # I doubt I'll always only have `:suppress`.

    def handle_cast([handle_pulse: %Pulse{type: :suppress}], s_circular) do
      Circular.time_to_die(s_circular)
      stop(s_circular)
    end

    def handle_cast([handle_pulse: %Pulse{} = pulse], s_circular) do
      result = Calc.run(s_circular.calc, on: pulse,
                                         with_state: s_circular.previously)

      Calc.cast_useful_result(result, s_circular)

      s_circular
      |> A.put(:previously, Calc.just_next_state(result))
      |> A.map(:throb, &Throb.note_pulse/1)
      |> continue
    end

    def handle_cast([throb: n], s_circular) do
      {action, next_throb} = Throb.throb(s_circular.throb, n)

      next_process_state = Map.put(s_circular, :throb, next_throb)
      case action do
        :continue ->
          continue(next_process_state)
        :stop ->
          Circular.time_to_die(next_process_state)
          stop(next_process_state)
      end
    end
  end

  handle_CALL do
    # Test support
    def handle_call(:current_strength, _from, s_circular) do
      strength = A.one!(s_circular, :current_strength)
      continue(s_circular, returning: strength)
    end
  end
end
