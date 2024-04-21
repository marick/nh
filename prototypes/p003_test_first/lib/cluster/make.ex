alias AppAnimal.{Cluster,System}

defmodule Cluster.Make do
  @moduledoc """
  Convenience functions for creating various "kinds" of clusters, ranging from
  generic to specialized. (The kinds are distinguished by the `label` field,
  which is used to create human-friendly logging messages.)

  Most functions are built on either a `linear` or `circular` cluster. To vary their
  base behavior, pipe the result into a `Map.put` that alters some field. You should
  also change the `label`.

  Both linear and circular clusters can send their outgoing pulses to other clusters
  or to `AffordanceLand` (external reality). The destination depends on whether it's
  a `Pulse` or `Action` being sent.

  Every cluster created will have a `calc` function specified. Return values for linear
  clusters are trivial: either a value or :no_result. But circular clusters can use
  some convenience functions to avoid having to code up the right tuple. See
  Cluster.Calc for more about return values.
  """

  use AppAnimal
  alias Cluster.Shape.{Circular, Linear}

  # Circular clusters

  def circular(name, calc \\ &Function.identity/1, opts \\ []) do
    struct(Cluster,
           name: name,
           label: :circular,
           shape: Circular.new(opts),
           calc: calc)
  end

  def no_pulse(next_state),          do: {:no_result, next_state}
  def pulse(pulse_data, next_state), do: {:useful_result, pulse_data, next_state}
  def pulse_and_save(data),          do: {:useful_result, data, data}


  # Linear Clusters

  def linear(name, calc \\ &Function.identity/1) do
    %Cluster{name: name, label: :linear,
             shape: Linear.new,
             calc: calc
    }
  end

  ## Edges

  def perception_edge(name) do
    linear(name, &Function.identity/1) |> labeled(:perception_edge)
  end

  def action_edge(name) do
    alias System.Action

    wrap_in_this_clusters_action = fn arg ->
      Action.new(name, arg)
    end

    linear(name, & [{name, &1}])
    |> Map.put(:calc, wrap_in_this_clusters_action)
    |> labeled(:action_edge)
  end


  ### Specializations

  def summarizer(name, calc) do
    linear(name, calc) |> labeled(:summarizer)
  end

  def gate(name, predicate) do
    f = fn pulse_data ->
      if predicate.(pulse_data),
         do: pulse_data,
         else: :no_result
    end

    linear(name, f) |> labeled(:gate)
  end


  def forward_unique(name, opts \\ []) do
    alias Cluster.Throb

    effectively_a_uuid = :erlang.make_ref()

    throb = Throb.counting_down_from(Duration.frequent_glance,
                                     on_pulse: &Throb.pulse_increases_lifespan/2)
    opts =
      opts
      |> Keyword.put_new(:initial_value, effectively_a_uuid)
      |> Keyword.put_new(:throb, throb)


    calc = fn pulse_data, previously ->
      if pulse_data == previously,
         do: :no_result,
         else: pulse_and_save(pulse_data)
    end
    circular(name, calc, opts) |> labeled(:forward_unique)
  end

  def delay(name, duration) do
    alias Cluster.Throb

    throb = Throb.counting_up_to(duration,
                                 on_pulse: &Throb.pulse_zeroes_lifespan/2,
                                 before_stopping: &Throb.pulse_current_value/2)

    f_stash_pulse_data = fn pulse_data, _previously ->
      {:no_result, pulse_data}
    end

    circular(name, f_stash_pulse_data, throb: throb)
  end

  private do
    def labeled(cluster, label), do: Map.put(cluster, :label, label)
  end
 end
