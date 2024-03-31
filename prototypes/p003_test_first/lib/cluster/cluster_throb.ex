alias AppAnimal.Cluster
alias Cluster.Throb

defmodule Throb do
  @moduledoc """
  Captures the handling of throbbing by a circular cluster.

  Periodic throb messages decrease the cluster's lifespan.
  Optionally, each pulse increases the lifespan. 
  """
  use AppAnimal
  use TypedStruct

  @type pulse_handler :: (Throb.t, any -> Throb.t)
  @type throb_handler :: (Throb.t, integer -> Throb.t)
  
  typedstruct enforce: true do
    plugin TypedStructLens, prefix: :l_

    field :current_age,       Duration.t,           required: true
    field :max_age,           Duration.t,           required: true
    field :f_throb,           throb_handler,        required: true
    field :f_note_pulse,      pulse_handler,        default: &__MODULE__.pulse_does_nothing/2
    field :f_before_stopping, (Cluster.t -> :none), default: &Function.identity/1
  end

  ### Init

  def counting_down_from(max_age, opts \\ []) do
    new_opts =
      [current_age: max_age, max_age: max_age, f_throb: &__MODULE__.count_down/2] ++
      Opts.replace_keys(opts, on_pulse: :f_note_pulse, before_stopping: :f_before_stopping)
    struct(__MODULE__, new_opts)
  end

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

  # Various values for `f_note_pulse`

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
end
