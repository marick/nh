alias AppAnimal.Cluster
alias Cluster.Throb

defmodule Throb do
  use TypedStruct
  
  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :current_strength, integer
    field :starting_strength, integer
    field :f_note_pulse, (Throb.t, any -> Throb.t)
  end

  def new(start_at, opts \\ []) do
    f_note_pulse = Keyword.get(opts, :on_pulse, &__MODULE__.pulse_does_nothing/2)
    %__MODULE__{current_strength: start_at,
                starting_strength: start_at,
                f_note_pulse: f_note_pulse
    }
  end

  def note_pulse(s_throb, cluster_calced) do
    s_throb.f_note_pulse.(s_throb, cluster_calced)
  end

  def throb(s_throb, n \\ 1) do
    mutated = Map.update!(s_throb, :current_strength, & &1-n)
    if mutated.current_strength <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
  end

  # Various values for `f_note_pulse`

  def pulse_does_nothing(s_throb, _cluster_calced_value),
      do: s_throb

  def pulse_increases_lifespan(s_throb, _cluster_calced_value) do
    next_strength = min(s_throb.starting_strength, s_throb.current_strength + 1)
    Map.put(s_throb, :current_strength, next_strength)
  end
end
