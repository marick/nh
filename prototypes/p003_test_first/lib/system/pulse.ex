alias AppAnimal.System

defmodule System.Pulse do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :type, atom, default: :default
    field :data, any,  required: true
  end

  def new(pulse_data) do
    %__MODULE__{data: pulse_data}
  end
end
