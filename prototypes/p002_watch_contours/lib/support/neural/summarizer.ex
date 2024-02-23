defmodule AppAnimal.Neural.Summarizer do
  @callback receive_pulse(any()) :: none()
  @callback summarize(any()) :: any()
  @callback describe_transformation(any(), any()) :: none()
  
  defmacro __using__(_) do
    quote do
      @behaviour AppAnimal.Neural.Summarizer
      
      def receive_pulse(input) do
        summary = summarize(input)
        describe_transformation(input, summary)
        send_pulse(summary)
        summary
      end

      def describe_transformation(input, summary) do end

      defoverridable receive_pulse: 1, describe_transformation: 2
    end
  end
end


  
