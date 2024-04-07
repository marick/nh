alias AppAnimal.System
alias System.{Pulse, Action, CannedResponse,Router}

defmodule Pulse do
  use TypedStruct

  typedstruct do
    field :type, atom, default: :default
    field :data, any,  required: true
  end

  def new(pulse_data), do: %__MODULE__{data: pulse_data}

  def new(type, pulse_data), do: %__MODULE__{type: type, data: pulse_data}
end


defmodule Action do
  @moduledoc """
  An action, to be sent to ActivityLand.

  The `type` tells ActivityLand what code should handle the action,
  and the `data` can be anything that code uses.
  """
  use TypedStruct

  typedstruct do
    field :type, atom, required: true
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

  typedstruct do
    field :downstream, atom, required: true
    field :pulse, Pulse.t,   required: true
  end

  def new(downstream, %Pulse{} = pulse),
      do: %__MODULE__{downstream: downstream, pulse: pulse}
  def new(downstream, data),
      do: new(downstream, Pulse.new(data))
end

defmodule Router do
  use TypedStruct
  alias System.Switchboard

  typedstruct do
    field :map, %{atom => pid}, required: true
  end

  def new(map), do: %__MODULE__{map: map}

  def pid_for(s_router, some_struct) do
    s_router.map[some_struct.__struct__]
  end

  def cast_via(s_router, %Pulse{} = pulse, to: destinations) do
    pid = pid_for(s_router, pulse)
    Switchboard.cast__distribute_pulse(pid, carrying: pulse, to: destinations)
  end
  
  def cast_via(s_router, %Pulse{} = pulse, from: source) do
    pid = pid_for(s_router, pulse)
    Switchboard.cast__distribute_pulse(pid, carrying: pulse, from: source)
  end
  
  def cast_via(s_router, %Action{} = action) do
    pid = pid_for(s_router, action)
    GenServer.cast(pid, {:take_action, action})
  end
  
end
