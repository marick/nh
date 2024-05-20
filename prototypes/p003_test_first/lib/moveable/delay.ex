alias AppAnimal.{Moveable,Clusterish,Network}

defmodule Moveable.Delay do
  use TypedStruct
  alias Moveable.Pulse

  typedstruct enforce: true do
    field :delay, Duration.t
    field :pulse, Pulse.t
  end

  def new(delay, %Pulse{} = pulse),
      do: %__MODULE__{delay: delay, pulse: pulse}
  def new(delay, pulse_data), do: new(delay, Pulse.new(pulse_data))
end

defimpl Moveable, for: Moveable.Delay do
  def cast(delay, cluster) do
    pid = Clusterish.pid_for(cluster, delay)
    Network.Timer.delayed(pid, delay.pulse,
                          after: delay.delay,
                          destination: cluster.name,
                          via_switchboard: Clusterish.pid_for(cluster, delay.pulse))
  end
end
