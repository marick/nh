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
  
  typedstruct enforce: true do
    plugin TypedStructLens, prefix: :l_

    field :current_lifespan,  integer,       default: Duration.frequent_glance
    field :starting_lifespan, integer,       default: Duration.frequent_glance
    field :f_note_pulse,      pulse_handler, default: &__MODULE__.pulse_does_nothing/2
  end

  @doc """
  Create the structure with one of the starting lifespan or the pulse handler.

  The other is left as the default.
  """
  def starting(response_to_pulse) when is_function(response_to_pulse, 2) do
    %__MODULE__{f_note_pulse: response_to_pulse}
  end

  def starting(starting_lifespan) when is_integer(starting_lifespan) do
    %__MODULE__{current_lifespan: starting_lifespan,
                starting_lifespan: starting_lifespan}
  end

  @doc """
  Create the structure with both optional values.
  """
  def starting(starting_lifespan, on_pulse: response_to_pulse) do
    %__MODULE__{current_lifespan: starting_lifespan,
                starting_lifespan: starting_lifespan,
                f_note_pulse: response_to_pulse
    }
  end
  

  def note_pulse(s_throb, cluster_calced) do
    s_throb.f_note_pulse.(s_throb, cluster_calced)
  end

  def throb(s_throb, n \\ 1) do
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
