alias AppAnimal.System

defmodule System.Router do
  use TypedStruct
  alias System.{Switchboard,Pulse,Action}

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
