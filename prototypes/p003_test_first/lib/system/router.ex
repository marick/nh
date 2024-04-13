alias AppAnimal.{System,Network}

defmodule System.Router do
  use AppAnimal
  use TypedStruct
  alias System.{Switchboard,Pulse,Action,Delay}

  typedstruct do
    field :map, %{atom => pid}, required: true
  end

  def new(map), do: %__MODULE__{map: map}

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

  def cast_via(s_router, %Delay{} = delay) do
    pid = pid_for(s_router, delay)
    Network.Timer.cast(pid, delay.pulse, after: delay.delay)
  end

  private do 
    def pid_for(s_router, %_name{} = some_struct) do
      s_router.map[some_struct.__struct__]
    end
  end
end
