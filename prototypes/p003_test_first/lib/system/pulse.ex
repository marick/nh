alias AppAnimal.System

defmodule System.Pulse do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :type, atom, default: :default
    field :data, any,  required: true
  end

  def new(pulse_data), do: %__MODULE__{data: pulse_data}

  def new(type, pulse_data), do: %__MODULE__{type: type, data: pulse_data}
end
