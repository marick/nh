alias AppAnimal.Cluster

defmodule Cluster.Make do
  use AppAnimal
  alias AppAnimal.Cluster.Variations.{Topology, Propagation}
  alias Topology.{Circular, Linear}
  alias Propagation.{Internal, External}


  # Circular clusters

  def circular(name, mutable_initializer, handle_pulse, opts \\ []) do
    handlers = %{
      pulse: handle_pulse,
      initialize: mutable_initializer
    }

    full_keyset =
      Keyword.merge(opts, label: :circular_cluster,
                          name: name,
                          topology: Circular.new(opts),
                          propagate: Internal.new(from_name: name),
                          handlers: handlers)

    struct(Cluster.Base, full_keyset)
  end

  # This is a very abbreviated version, mainly for tests.
  def circular(name, handle_pulse) when is_function(handle_pulse) do
    circular(name, fn _configuration -> %{} end, handle_pulse)
  end

  # This can be useful if the cluster's state is set at initialization and
  # thereafter not changed.
  def one_pulse(after: calc) when is_function(calc, 1) do
    fn pulse_data, mutable, configuration ->
      configuration.send_pulse_downstream.(carrying: calc.(pulse_data))
      mutable
    end    
  end
  
  def one_pulse(after: calc) when is_function(calc, 2) do
    fn pulse_data, mutable, configuration ->
      {new_pulse, mutated} = calc.(pulse_data, mutable)
      configuration.send_pulse_downstream.(carrying: new_pulse)
      mutated
    end
  end
  
  # Linear Clusters

  def linear(name, handle_pulse) when is_function(handle_pulse) do
    %Cluster.Base{name: name, label: :linear_cluster,
                  topology: Linear.new,
                  propagate: Internal.new(from_name: name),
                  handlers: %{handle_pulse: handle_pulse}}
  end

  def linear(name, calc: f) do
    linear(name, only_pulse(after: f))
  end

  def linear(only_name), do: linear(only_name, calc: fn _ -> :no_data end)

  def only_pulse(after: calc) when is_function(calc, 1) do
    fn pulse_data, configuration ->
      configuration.send_pulse_downstream.(carrying: calc.(pulse_data))
      :there_is_never_a_meaningful_return_value
    end
  end
  

  ## Edges

  def perception_edge(name) do
    just_forward_pulse_data = fn pulse_data, configuration -> 
      configuration.send_pulse_downstream.(carrying: pulse_data)
      :there_is_never_a_meaningful_return_value
    end
    %Cluster.Base{name: name, label: :perception_edge,
                  topology: Linear.new,
                  propagate: Internal.new(from_name: name),
                  handlers: %{handle_pulse: just_forward_pulse_data}}
  end
  

  def action_edge(name) do
    %Cluster.Base{name: name, label: :action_edge,
                  topology: Linear.new,
                  calc: & [{name, &1}],
                  propagate: External.new(AppAnimal.Neural.Affordances, :note_action)}
  end
 end
