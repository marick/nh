defmodule AppAnimal.Pids do
  @moduledoc """
  The collection of pids that make up the whole system.

  This includes direct access to processes inside the `Network`
  structure, namely `p_circular_clusters` and `p_timer`. Mostly used
  by tests. I suppose there should be more information hiding
  somewhere around here.
  """
  use TypedStruct

  typedstruct enforce: true do
    plugin TypedStructLens

    field :p_switchboard,       pid
    field :p_affordland,        pid    # This name is perhaps unfortunate
    field :p_logger,            pid

    field :p_circular_clusters, pid
    field :p_timer,             pid
  end

end
