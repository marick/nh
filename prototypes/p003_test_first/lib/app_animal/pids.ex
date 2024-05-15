defmodule AppAnimal.Pids do
  @moduledoc "The collection of pids that make up the whole system."
  use TypedStruct

  typedstruct do
    plugin TypedStructLens

    field :p_switchboard,       pid
    field :p_affordland,        pid    # This name is perhaps unfortunate
    field :p_logger,            pid
    field :p_circular_clusters, pid
    field :p_timer,             pid
  end

end
