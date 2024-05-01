alias AppAnimal.System

defmodule System.Router do
  use AppAnimal
  use TypedStruct

  typedstruct enforce: true do
    field :map, %{atom => pid}
  end

  def new(map), do: %__MODULE__{map: map}

  def pid_for(s_router, %_name{} = some_struct) do
    s_router.map[some_struct.__struct__]
  end
end
