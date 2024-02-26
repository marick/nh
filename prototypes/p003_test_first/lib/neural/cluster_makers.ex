defmodule AppAnimal.Neural.ClusterMakers do
  alias AppAnimal.Neural
  
  def cluster(name, module, handle_pulse) do
    module.new(name, handle_pulse)
  end

  def circular_cluster(name, handle_pulse) when is_function(handle_pulse) do
    circular_cluster(name,
                     fn _configuration -> "process has no mutable state" end,
                     handle_pulse)
  end

  def circular_cluster(name, initialize, handle_pulse) do
    handlers = %{initialize: initialize, pulse: handle_pulse}
    %Neural.CircularCluster{name: name, handlers: handlers}
  end
end
