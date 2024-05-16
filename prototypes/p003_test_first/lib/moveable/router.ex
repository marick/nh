defmodule AppAnimal.Moveable.Router do
  @moduledoc """
  A structure that maps from the name of a `Moveable` to the pid of a process that
  handles such moveables.

  For example:

      use Moveable.MoveableAliases

      Router.new(%{Pulse => p_switchboard,
                   Action => p_affordland,
                   ...})

  Note that the names are fully qualified module names.
  """
  use AppAnimal

  typedstruct enforce: true do
    field :moveable_name_to_pid, %{atom => pid}
  end

  def new(moveable_name_to_pid),
      do: %__MODULE__{moveable_name_to_pid: moveable_name_to_pid}

  def pid_for(s_router, %moveable_name{} = _some_struct) do
    s_router.moveable_name_to_pid[moveable_name]
  end
end
