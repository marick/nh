defmodule AppAnimal.Neural.AdjacentSummarizer do
  @callback activate() :: none()
  @callback summarize() :: any()
  @callback describe_summary(any()) :: none()
  
  defmacro __using__(environment: environment, switchboard: switchboard) do
    quote do
      use AppAnimal.Neural.LinearCluster, switchboard: unquote(switchboard)
      @behaviour AppAnimal.Neural.AdjacentSummarizer
      
      def activate() do
        summary = GenServer.call(unquote(environment), summarize_with: &summarize/1)
        describe_summary(summary)
        activate_downstream(summary)
      end

      def summarize() do
        GenServer.call(unquote(environment), summarize_with: &summarize/1)
      end

      def describe_summary(summary) do end

      defoverridable activate: 0, summarize: 0, describe_summary: 1
    end
    
  end
end


  
