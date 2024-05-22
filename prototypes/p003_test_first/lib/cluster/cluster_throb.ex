alias AppAnimal.Cluster

defmodule Cluster.Throb do
  @moduledoc """
  Captures the handling of throbbing by a circular cluster.

  Periodic throb messages will either increase or decrease the
  cluster's strength. The process stops when it hits a limit value
  (`max_strength` or zero).

  Additionally, each pulse received may affect the
  strength. Typically, receipt of pulses makes the cluster live
  longer.
  """
  use AppAnimal
  use KeyConceptAliases

  @type throb_handler :: (Throb.t, integer -> Throb.t)
  @type pulse_handler :: (Throb.t, any -> Throb.t)

  typedstruct enforce: true do
    plugin TypedStructLens

    field :current_strength,  Duration.t
    field :max_strength,      Duration.t
    field :f_throb,           throb_handler

    field :f_note_pulse,      pulse_handler,        default: &__MODULE__.pulse_does_nothing/1
  end

  section "Simple initialization" do

      @doc """
      If you don't care about throbbing behavior, use this.
      """
    def default() do
      counting_down_from(Duration.frequent_glance,
                         on_pulse: &Throb.pulse_increases_strength/1)
    end

      @doc """
      Create a Throb that counts down from a `max_strength` and signals that
      the process is to stop when it hits zero.

      ## Options:
        * `:on_pulse` - a function that takes a `Throb` and the new state of the process and
          adjusts the `current_strength`.
      """
    def counting_down_from(max_strength, opts \\ []) do
      opts
      |> Opts.put_missing!(current_strength: max_strength, max_strength: max_strength, f_throb: &__MODULE__.count_down/2)
      |> Opts.rename(:on_pulse, to: :f_note_pulse)
      |> then(& struct(__MODULE__, &1))
    end

      @doc """
      Same as `counting_down_from/2`, except that it counts up from zero.

      The `before_stopping` function is called when the strength hits `max_strength`.
      """
    def counting_up_to(max_strength, opts \\ []) do
      opts
      |> Opts.put_missing!(current_strength: 0, max_strength: max_strength, f_throb: &__MODULE__.count_up/2)
      |> Opts.rename(:on_pulse, to: :f_note_pulse)
      |> then(& struct(__MODULE__, &1))
    end

    @doc "Throbs have no effect; the cluster never ages out."
    def ignore(), do: counting_up_to(Duration.foreverish)
  end

  section "Finer control over handling of 'throb' messages" do

    def count_down(s_throb, n \\ 1) do
      mutated = Map.update!(s_throb, :current_strength, & &1-n)
      if mutated.current_strength <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
    end

    def count_up(s_throb, n \\ 1) do
      mutated = Map.update!(s_throb, :current_strength, & &1+n)
      if mutated.current_strength >= s_throb.max_strength,
         do: {:stop, mutated},
         else: {:continue, mutated}
    end
  end

  section "Finer control over handling pulses (in addition to `calc` behavior)" do

    def pulse_does_nothing(s_throb),
        do: s_throb

    def pulse_increases_strength(s_throb) do
      next_strength = min(s_throb.max_strength, s_throb.current_strength + 1)
      Map.put(s_throb, :current_strength, next_strength)
    end

    def pulse_zeroes_strength(s_throb) do
      Map.put(s_throb, :current_strength, 0)
    end
  end

  section "Implementation of chosen behavior" do
    @doc "React to a periodic throb message."
    def throb(s_throb, n \\ 1),
        do: s_throb.f_throb.(s_throb, n)

    @doc "React to an incomping pulse, using whatever value it calculated."
    def note_pulse(s_throb),
        do: s_throb.f_note_pulse.(s_throb)
  end
end
