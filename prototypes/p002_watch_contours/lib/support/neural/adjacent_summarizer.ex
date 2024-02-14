defmodule AppAnimal.Neural.AdjacentSummarizer do
  @callback activate() :: none()
  @callback downstream_data() :: any()
  
  defmacro __using__(environment: environment, switchboard: switchboard) do
    quote do
      use AppAnimal.Neural.LinearCluster, switchboard: unquote(switchboard)
      @behaviour AppAnimal.Neural.AdjacentSummarizer
      
      def activate() do
        paragraph_shape = downstream_data()
        Logger.info("edge structure: #{edge_string paragraph_shape}")
        activate_downstream(paragraph_shape)
      end

      def downstream_data() do
        GenServer.call(unquote(environment), summarize_with: &edge_structure/1)
      end
      defoverridable activate: 0, downstream_data: 0
    end
    
  end
end


  
