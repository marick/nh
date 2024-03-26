alias AppAnimal.Cluster.ThrobLogic

defmodule ThrobLogic do
  use TypedStruct
  
  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :current_strength, integer
    field :starting_strength, integer
  end

  def new(start_at) do
    %__MODULE__{current_strength: start_at, starting_strength: start_at}
  end

  def note_pulse(s_throb_logic, _calc_value) do
    s_throb_logic
  end

  def throb(s_throb_logic) do
    
    mutated = Map.update!(s_throb_logic, :current_strength, & &1-1)
    if mutated.current_strength <= 0,
         do: {:stop, mutated},
         else: {:continue, mutated}
  end
end
