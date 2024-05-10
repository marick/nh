alias AppAnimal.Cluster

defmodule Cluster.Throb do
  @moduledoc """
  Captures the handling of throbbing by a circular cluster.

  Periodic throb messages will either increase or decrease the
  cluster's lifespan. The process stops when it hits a limit value
  (`max_age` or zero).

  Additionally, each pulse received may affect the
  lifespan. Typically, receipt of pulses makes the cluster live
  longer.
  """
  use AppAnimal
  use KeyConceptAliases
  alias System.Pulse

  @type throb_handler :: (Throb.t, integer -> Throb.t)
  @type pulse_handler :: (Throb.t, any -> Throb.t)

  typedstruct enforce: true do
    plugin TypedStructLens

    field :current_age,       Duration.t
    field :max_age,           Duration.t
    field :f_throb,           throb_handler

    field :f_note_pulse,      pulse_handler,        default: &__MODULE__.pulse_does_nothing/1
    field :f_before_stopping, (Cluster.t -> :none), default: &__MODULE__.stop_silently/2
  end

  section "Simple initialization" do

      @doc """
      If you don't care about throbbing behavior, use this.
      """
    def default() do
      counting_down_from(Duration.frequent_glance,
                         on_pulse: &Throb.pulse_increases_lifespan/1)
    end

      @doc """
      Create a Throb that counts down from a `max_age` and signals that
      the process is to stop when it hits zero.

      ## Options:
        * `:on_pulse` - a function that takes a `Throb` and the new state of the process and
          adjusts the `current_age`.
        * `before_stopping` - a function that takes the new state of the process.
          It will typically send a pulse downstream.
      """
    def counting_down_from(max_age, opts \\ []) do
      opts
      |> Opts.put_new!(current_age: max_age, max_age: max_age, f_throb: &__MODULE__.count_down/2)
      |> Opts.rename(:on_pulse, to: :f_note_pulse)
      |> Opts.rename(:before_stopping, to: :f_before_stopping)
      |> then(& struct(__MODULE__, &1))
    end

      @doc """
      Same as `counting_down_from/2`, except that it counts up from zero.

      The `before_stopping` function is called when the age hits `max_age`.
      """
    def counting_up_to(max_age, opts \\ []) do
      new_opts =
        [current_age: 0, max_age: max_age, f_throb: &__MODULE__.count_up/2] ++
        Opts.replace_keys(opts, on_pulse: :f_note_pulse, before_stopping: :f_before_stopping)
      struct(__MODULE__, new_opts)
    end
  end

  section "Finer control over handling of 'throb' messages" do

    def count_down(s_throb, n \\ 1) do
      mutated = Map.update!(s_throb, :current_age, & &1-n)
      if mutated.current_age <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
    end

    def count_up(s_throb, n \\ 1) do
      mutated = Map.update!(s_throb, :current_age, & &1+n)
      if mutated.current_age >= s_throb.max_age,
         do: {:stop, mutated},
         else: {:continue, mutated}
    end
  end

  section "Finer control over handling pulses (in addition to `calc` behavior)" do

    def pulse_does_nothing(s_throb),
        do: s_throb

    def pulse_increases_lifespan(s_throb) do
      next_lifespan = min(s_throb.max_age, s_throb.current_age + 1)
      Map.put(s_throb, :current_age, next_lifespan)
    end

    def pulse_zeroes_lifespan(s_throb) do
      Map.put(s_throb, :current_age, 0)
    end
  end

  section "Control over end-of-life behavior" do
    def stop_silently(_s_process_state, _pulse_value) do
      :no_return_value
    end

    def pulse_current_value(s_process_state, pulse_value) do
      System.Moveable.cast(Pulse.new(pulse_value), s_process_state)
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
