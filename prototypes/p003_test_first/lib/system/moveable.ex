alias AppAnimal.{System,Network,Clusterish}
alias System.{Pulse, Action, Affordance, Delay}
alias System.{Moveable}


defprotocol Moveable do
  @spec cast(t, Clusterish.t) :: none
  def cast(moveable, cluster)
end


#######

defmodule Pulse do
  use TypedStruct

  typedstruct enforce: true do
    field :type, atom, default: :default
    field :data, any
  end

  def new(type, pulse_data), do: %__MODULE__{type: type, data: pulse_data}
  def new(pulse_data), do: %__MODULE__{data: pulse_data}
  def new, do: new(:no_data)

  def suppress(), do: new(:suppress, :no_data)

  @doc """
  Return a Pulse argument or convert into a *default* Pulse."
  """

  def ensure(data) do
    case data do
      nil ->
        __MODULE__.new
      %__MODULE__{} = pulse ->
        pulse
      pulse_data ->
        __MODULE__.new(pulse_data)
    end
  end
end

defimpl Moveable, for: Pulse do
  def cast(pulse, cluster) do
    pid = Clusterish.pid_for(cluster, pulse)

    System.Switchboard.cast(pid, :distribute_pulse, carrying: pulse,
                                                    from: Clusterish.name(cluster))
  end
end

#######


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

defimpl Moveable, for: Action do
  def cast(action, cluster) do
    pid = Clusterish.pid_for(cluster, action)
    GenServer.cast(pid, {:take_action, action})
  end
end

#######

defmodule Affordance do
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

#######

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

defimpl Moveable, for: Delay do
  def cast(delay, cluster) do
    pid = Clusterish.pid_for(cluster, delay)
    Network.Timer.delayed(pid, delay.pulse,
                          after: delay.delay,
                          destination: cluster.name,
                          via_switchboard: Clusterish.pid_for(cluster, delay.pulse))
  end
end


####

defmodule Moveable.Collection do
  use TypedStruct

  typedstruct enforce: true do
    field :members, MapSet.t(Moveable.t)
  end

  def new(collection), do: %__MODULE__{members: collection}
end

defimpl Moveable, for: Moveable.Collection do
  def cast(collection, cluster) do
    for moveable <- collection.members, do: Moveable.cast(moveable, cluster)
  end
end
