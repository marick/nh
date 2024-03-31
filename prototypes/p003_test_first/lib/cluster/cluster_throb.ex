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

    field :current_lifespan,  integer,       default: Duration.frequent_glance
    field :starting_lifespan, integer,       default: Duration.frequent_glance
    field :f_note_pulse,      pulse_handler, default: &__MODULE__.pulse_does_nothing/2
    field :f_throb,           throb_handler, default: &__MODULE__.count_down/2
    field :f_exit_action,     (Cluster.t -> :none), default: &Function.identity/1
  end

  @doc """
  Create the structure with a given starting_lifespan (the most common case)
  """
  def starting(starting_lifespan) when is_integer(starting_lifespan) do
    %__MODULE__{starting_lifespan: starting_lifespan, current_lifespan: starting_lifespan}
  end

  IO.puts "======================================= NEXT start adding an f_throb action"

  def starting(opts) when is_list(opts) do
    opts 
    |> Opts.replace_keys(on_pulse: :f_note_pulse)
    |> Opts.copy(:current_lifespan, from_existing: :starting_lifespan)
    |> then(& struct(__MODULE__, &1))
  end

  def note_pulse(s_throb, cluster_calced),
      do: s_throb.f_note_pulse.(s_throb, cluster_calced)

  def throb(s_throb, n \\ 1),
      do: s_throb.f_throb.(s_throb, n)

  def count_down(s_throb, n \\ 1) do
    mutated = Map.update!(s_throb, :current_lifespan, & &1-n)
    if mutated.current_lifespan <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
  end

  # Various values for `f_note_pulse`

  def pulse_does_nothing(s_throb, _cluster_calced_value),
      do: s_throb

  def pulse_increases_lifespan(s_throb, _cluster_calced_value) do
    next_lifespan = capped_at(s_throb.starting_lifespan, s_throb.current_lifespan + 1)
    Map.put(s_throb, :current_lifespan, next_lifespan)
  end

  defp capped_at(cap, proposed_value) do
    if proposed_value < cap,
       do: proposed_value,
       else: cap
  end
end
