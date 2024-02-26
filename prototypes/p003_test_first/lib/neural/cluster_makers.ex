defmodule AppAnimal.Neural.ClusterMakers do
  alias AppAnimal.Neural
  
  def cluster(name, module, handle_pulse) do
    module.new(name, handle_pulse)
  end

  def circular_cluster(name, handle_pulse, keys \\ []) when is_function(handle_pulse) do
    initialize = Keyword.get(keys, :initialize_mutable,
                             fn _configuration -> "process has no mutable state" end)
    handlers = %{initialize: initialize, pulse: handle_pulse}
    %Neural.CircularCluster{name: name, handlers: handlers}
  end
end
