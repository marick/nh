alias AppAnimal.{Moveable,Clusterish}

defmodule Moveable.Pulse do
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

defimpl Moveable, for: Moveable.Pulse do
  def cast(pulse, cluster) do
    pid = Clusterish.pid_for(cluster, pulse)

    AppAnimal.Switchboard.cast(pid, :fan_out_pulse, pulse, from: Clusterish.name(cluster))
  end
end
