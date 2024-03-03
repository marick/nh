defmodule AppAnimal.Neural.Cluster do
  alias AppAnimal.Neural

  # Circular clusters

  def circular(name, mutable_initializer, handle_pulse, keys \\ []) do
    handlers = %{
      pulse: handle_pulse,
      initialize: mutable_initializer
    }

    full_keyset =
      Keyword.merge(keys, name: name, handlers: handlers)

    struct(Neural.CircularCluster, full_keyset)
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
    %Neural.LinearCluster{name: name, handlers: %{handle_pulse: handle_pulse}}
  end

  def linear(name, calc: f) do
    linear(name, only_pulse(after: f))
  end

  def only_pulse(after: calc) when is_function(calc, 1) do
    fn pulse_data, configuration ->
      configuration.send_pulse_downstream.(carrying: calc.(pulse_data))
      :there_is_never_a_meaningful_return_value
    end
  end
  

  ## Edges

  def perception_edge(name) do
    %Neural.PerceptionEdge{name: name}
  end

 end
