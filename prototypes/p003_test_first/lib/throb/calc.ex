alias AppAnimal.Throb

defmodule Throb.Calc do
  use TypedStruct
  
  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :current_strength, integer
    field :starting_strength, integer
  end

  def new(start_at) do
    %__MODULE__{current_strength: start_at, starting_strength: start_at}
  end

  def note_pulse(s_calc, _cluster_calc) do
    s_calc
  end

  def throb(s_calc, n \\ 1) do
    mutated = Map.update!(s_calc, :current_strength, & &1-n)
    if mutated.current_strength <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
  end
end
