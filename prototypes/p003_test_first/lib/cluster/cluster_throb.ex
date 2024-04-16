alias AppAnimal.{Cluster,System}
alias Cluster.Throb

defmodule Throb do
  @moduledoc """
  Captures the handling of throbbing by a circular cluster.

  Periodic throb messages will either increase or decrease the
  cluster's lifespan. The process stops when it hits a limit value
  (`max_age` or zero).

  Optionally, each pulse can affect the lifespan. Typically, receipt of
  pulses makes the cluster live longer. So in the absence of pulses, the
  cluster will eventually "age out". 
  """
  use AppAnimal
  use TypedStruct
  alias System.Pulse

  @type throb_handler :: (Throb.t, integer -> Throb.t)
  @type pulse_handler :: (Throb.t, any -> Throb.t)
  
  typedstruct enforce: true do
    plugin TypedStructLens

    field :current_age,       Duration.t,           required: true
    field :max_age,           Duration.t,           required: true
    field :f_throb,           throb_handler,        required: true
    field :f_note_pulse,      pulse_handler,        default: &__MODULE__.pulse_does_nothing/2
    field :f_before_stopping, (Cluster.t -> :none), default: &__MODULE__.stop_silently/2
  end

  ### Init

  @doc """
  Create a cluster that counts down from a `max_age` and signals that
  the process is to stop when it hits zero.

  ## Options:

    * `:on_pulse` - a function that takes a `Throb` and the new state of the process and
      adjusts the `current_age`.
    * `before_stopping` - a function that takes the new state of the process. It will typically
      send a pulse downstream.
  """
  def counting_down_from(max_age, opts \\ []) do
    new_opts =
      [current_age: max_age, max_age: max_age, f_throb: &__MODULE__.count_down/2] ++
      Opts.replace_keys(opts, on_pulse: :f_note_pulse, before_stopping: :f_before_stopping)
    struct(__MODULE__, new_opts)
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
  
  ### API

  def note_pulse(s_throb, cluster_calced),
      do: s_throb.f_note_pulse.(s_throb, cluster_calced)

  def throb(s_throb, n \\ 1),
      do: s_throb.f_throb.(s_throb, n)

  ## Functions that handle throbbing.
  
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

  # Functions that handle pulses.

  def pulse_does_nothing(s_throb, _cluster_calced_value),
      do: s_throb

  def pulse_increases_lifespan(s_throb, _cluster_calced_value) do
    next_lifespan = capped_at(s_throb.max_age, s_throb.current_age + 1)
    Map.put(s_throb, :current_age, next_lifespan)
  end

  def pulse_zeroes_lifespan(s_throb, _cluster_calced_value) do
    Map.put(s_throb, :current_age, 0)
  end

  defp capped_at(cap, proposed_value) do
    if proposed_value < cap,
       do: proposed_value,
       else: cap
  end


  # Functions that handle stopping

  def stop_silently(_s_process_state, _pulse_value) do
    :no_return_value
  end

  def pulse_current_value(s_process_state, pulse_value) do
    Cluster.start_pulse_on_its_way(s_process_state, Pulse.new(pulse_value))
  end
end
