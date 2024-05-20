alias AppAnimal.{Moveable,Clusterish}

defmodule Moveable.Action do
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

defimpl Moveable, for: Moveable.Action do
  def cast(action, cluster) do
    pid = Clusterish.pid_for(cluster, action)
    GenServer.cast(pid, {:take_action, action})
  end
end
