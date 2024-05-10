alias AppAnimal.{Cluster,System}

defmodule Cluster.Circular do
  @moduledoc """
  The structure that serves as state for a circular process.

  # The two fields different from a linear cluster are these:

  - throb          - Controls the aging of this cluster and its eventual exit.
  - previously     - The part of the state the `calc` function can channged.
  """
  use AppAnimal
  alias System.{Moveable, Pulse}
  @derive [AppAnimal.Clusterish]

  typedstruct enforce: true do
    plugin TypedStructLens

    # You may note that `Linear` consists entirely of the following fields;
    # `Circular` is a superset. I can't think of a a solution that pleases me
    # and works with Elixir.

    field :name, atom  # This is more convenient than `id`
    field :id, Cluster.Identification.t
    field :calc, fun
    field :router, System.Router.t

    field :previously, any
    field :throb, Cluster.Throb.t
    field :f_while_stopping, (t -> :none)
  end

  deflens current_age(), do: in_throb(:current_age)
  deflens max_age(), do: in_throb(:max_age)

  private do
    def in_throb(key), do: throb() |> Lens.key!(key)
  end

  section "Control over end-of-life behavior" do
    def stop_silently(_s_circular) do
      :no_return_value
    end

    def pulse_current_value(s_circular) do
      Moveable.cast(Pulse.new(s_circular.previously), s_circular)
    end

    @doc "Call this before the owning process stops."
    def time_to_die(s_circular) do
      s_circular.throb.f_before_stopping.(s_circular, s_circular.previously)
    end
  end
end
