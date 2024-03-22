alias AppAnimal.Cluster

defmodule Cluster.Make do
  @moduledoc """
  Convenience functions for creating various "kinds" of clusters, ranging from
  generic to specialized. (The kinds are distinguished by the `label` field,
  which is used to create human-friendly logging messages.)

  Most functions are built on either a `linear` or `circular` cluster. To vary their
  base behavior, pipe the result into a `Map.put` that alters some field. You should
  also change the `label`.

  Both linear and circular clusters can send their outgoing pulses to other clusters
  or to `AffordanceLand` (external reality). You use `OutgoingLogic.mkfn_pulse_direction`
  to choose.

  Most every cluster created will have a function specified. Return values for linear
  clusters are trivial: either a value or :no_pulse. But circular clusters can use
  some convenience functions to avoid having to code up the right tuple.
  """
  
  use AppAnimal
  alias Cluster.Shape.{Circular, Linear}
  alias AppAnimal.Neural.{AffordanceLand, Switchboard}
  alias Cluster.OutgoingLogic

  # Circular clusters

  def circular(name, calc \\ &Function.identity/1, opts \\ []) do
    struct(Cluster,
           name: name,
           label: :circular_cluster,
           shape: Circular.new(opts),
           calc: calc,
           f_outward: OutgoingLogic.mkfn_pulse_direction(Switchboard, name))
  end


  def pulse(pulse_data, next_state), do: {:pulse, pulse_data, next_state}
  def no_pulse(next_state), do: {:no_pulse, next_state}
  def pulse_and_save(data), do: {:pulse, data, data}

  
  # Linear Clusters

  def linear(name, calc \\ &Function.identity/1) do
    %Cluster{name: name, label: :linear_cluster,
             shape: Linear.new,
             calc: calc,
             f_outward: OutgoingLogic.mkfn_pulse_direction(Switchboard, name)
    }
  end

  ## Edges

  def perception_edge(name) do
    linear(name, &Function.identity/1)
    |> Map.put(:label, :perception_edge)
  end

  def action_edge(name) do
    linear(name, & [{name, &1}])
    |> Map.put(:f_outward, OutgoingLogic.mkfn_pulse_direction(AffordanceLand))
    |> Map.put(:label, :action_edge)
  end
 end
