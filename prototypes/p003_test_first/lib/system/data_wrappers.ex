alias AppAnimal.System
alias System.{Pulse, Action, CannedResponse, Delay}

defmodule Pulse do
  use TypedStruct

  typedstruct enforce: true do
    field :type, atom, default: :default
    field :data, any
  end

  def new(type, pulse_data), do: %__MODULE__{type: type, data: pulse_data}

  def new(pulse_data), do: %__MODULE__{data: pulse_data}

  def new, do: new(:no_data)
end


defmodule Action do
  @moduledoc """
  An action, to be sent to ActivityLand.

  The `type` tells ActivityLand what code should handle the action,
  and the `data` can be anything that code uses.
  """
  use TypedStruct

  typedstruct enforce: true do
    field :type, atom
    field :data, any,  default: :action_takes_no_data
  end

  def new(type), do: %__MODULE__{type: type}
  def new(type, action_data), do: %__MODULE__{type: type, data: action_data}
end


defmodule CannedResponse do
  @moduledoc """
  Describes how an action turns into a pulse sent to a PerceptionEdge.
  """
  use TypedStruct

  typedstruct enforce: true do
    field :downstream, atom
    field :pulse, Pulse.t
  end

  def new(downstream, %Pulse{} = pulse),
      do: %__MODULE__{downstream: downstream, pulse: pulse}
  def new(downstream, data),
      do: new(downstream, Pulse.new(data))
end

defmodule Delay do
  use TypedStruct

  typedstruct enforce: true do
    field :delay, Duration.t
    field :pulse, Pulse.t
  end

  def new(delay, %Pulse{} = pulse),
      do: %__MODULE__{delay: delay, pulse: pulse}
  def new(delay, pulse_data), do: new(delay, Pulse.new(pulse_data))
end
