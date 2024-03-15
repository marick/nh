alias AppAnimal.Cluster

defmodule Cluster.Make do
  use AppAnimal
  alias Cluster.Shape.{Circular, Linear}
  alias Cluster.PulseLogic
  alias PulseLogic.{Internal, External}


  # Circular clusters

  def circular(name, calc, opts \\ []) do
    struct(Cluster,
           name: name,
           label: :circular_cluster,
           shape: Circular.new(opts),
           calc: calc,
           pulse_logic: PulseLogic.Internal.new(from_name: name)
    )
  end

  def pulse_and_save(f) when is_function(f, 2) do
    fn pulse, mutable ->
      mutated = f.(pulse, mutable)
      pulse(mutated, mutated)
    end
  end

  def pulse(pulse_data, mutated), do: {:pulse, pulse_data, mutated}
  def no_pulse(mutated), do: {:no_pulse, mutated}
  def no_pulse(), do: {:no_pulse}

  
  # Linear Clusters

  def linear(name, calc) do
    %Cluster{name: name, label: :linear_cluster,
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
    %Cluster{name: name, label: :action_edge,
             shape: Linear.new,
             calc: & [{name, &1}],
             pulse_logic: External.new(AppAnimal.Neural.Affordances, :note_action)}
  end
 end
