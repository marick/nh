alias AppAnimal.Cluster

defmodule Cluster.Make do
  use AppAnimal
  alias Cluster.Shape.{Circular, Linear}
  alias Cluster.PulseLogic
  alias PulseLogic.{Internal, External}


  # Circular clusters

  def circular2(name, calc, opts \\ []) do
    struct(Cluster.Base,
           name: name,
           label: :circular_cluster,
           shape: Cluster.Shape.Circular.new(opts),
           calc: calc,
           pulse_logic: Cluster.PulseLogic.Internal.new(from_name: name)
    )
  end

  def circular(name, mutable_initializer, handle_pulse, opts \\ []) do
    handlers = %{
      pulse: handle_pulse,
      initialize: mutable_initializer
    }

    full_keyset =
      Keyword.merge(opts, label: :circular_cluster,
                          name: name,
                          shape: Circular.new(opts),
                          pulse_logic: Internal.new(from_name: name),
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

  def linear(name, calc) do
    %Cluster.Base{name: name, label: :linear_cluster,
                  shape: Linear.new,
                  calc: calc,
                  pulse_logic: Internal.new(from_name: name)
     }
  end

  ## Edges

  def perception_edge(name) do
    linear(name, &Function.identity/1)
    |> Map.put(:label, :perception_edge)
  end
  

  def action_edge(name) do
    %Cluster.Base{name: name, label: :action_edge,
                  shape: Linear.new,
                  calc: & [{name, &1}],
                  pulse_logic: External.new(AppAnimal.Neural.Affordances, :note_action)}
  end
 end
