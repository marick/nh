defmodule AppAnimal.Neural.ClusterMakers do
  alias AppAnimal.Neural

  # Surely this could be less ugly
  def circular_cluster(name, handle_pulse, keys \\ []) when is_function(handle_pulse) do
    {handler_instructions, structure_template} =
      keys
      |> Keyword.merge(name: name, handle_pulse: handle_pulse)
      |> Keyword.split([:handle_pulse, :initialize_mutable])

    handlers = %{
      pulse: Keyword.get(handler_instructions, :handle_pulse),
      initialize: Keyword.get(handler_instructions, :initialize_mutable, 
                              fn _configuration -> %{} end)
    }

    struct(Neural.CircularCluster, Keyword.put_new(structure_template, :handlers, handlers))
  end


  def linear_cluster(name, handle_pulse) when is_function(handle_pulse) do
    %Neural.LinearCluster{name: name, handlers: %{handle_pulse: handle_pulse}}
  end

  def affordance(name) do
    %Neural.Affordance{name: name}
  end
end
