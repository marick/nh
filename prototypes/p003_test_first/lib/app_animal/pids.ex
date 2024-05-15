defmodule AppAnimal.Pids do
  use TypedStruct

  typedstruct do
    plugin TypedStructLens

    field :p_switchboard,       pid
    field :p_affordances,       pid
    field :p_logger,            pid
    field :p_circular_clusters, pid
    field :p_timer,             pid
  end

end
