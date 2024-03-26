alias AppAnimal.Throb

defmodule Throb.Calc do
  use TypedStruct
  
  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :current_strength, integer
    field :starting_strength, integer
    field :f_note_pulse, (Throb.Calc.t, any -> Throb.Calc.t)
  end

  def new(start_at, opts \\ []) do
    f_note_pulse = Keyword.get(opts, :on_pulse, &pulse_does_nothing/2)
    %__MODULE__{current_strength: start_at,
                starting_strength: start_at,
                f_note_pulse: f_note_pulse
    }
  end

  def note_pulse(s_calc, cluster_calc) do
    s_calc.f_note_pulse.(s_calc, cluster_calc)
  end

  def throb(s_calc, n \\ 1) do
    mutated = Map.update!(s_calc, :current_strength, & &1-n)
    if mutated.current_strength <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
  end

  # Various values for `f_note_pulse`

  def pulse_does_nothing(s_calc, _cluster_calc), do: s_calc
end
