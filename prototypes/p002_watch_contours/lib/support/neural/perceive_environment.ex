defmodule AppAnimal.Neural.PerceiveEnvironment do
  @callback receive_pulse() :: none()
  @callback summarize() :: any()
  @callback describe_summary(any()) :: none()
  
  defmacro __using__(environment: environment) do
    quote do
      @behaviour AppAnimal.Neural.PerceiveEnvironment
      
      def receive_pulse() do
        summary = GenServer.call(unquote(environment), summarize_with: &summarize/1)
        describe_summary(summary)
        send_pulse(summary)
      end

      def summarize() do
        GenServer.call(unquote(environment), summarize_with: &summarize/1)
      end

      def describe_summary(summary) do end

      defoverridable receive_pulse: 0, summarize: 0, describe_summary: 1
    end
    
  end
end


  
