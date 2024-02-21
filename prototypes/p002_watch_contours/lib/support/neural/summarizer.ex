defmodule AppAnimal.Neural.Summarizer do
  @callback activate(any()) :: none()
  @callback summarize(any()) :: any()
  @callback describe_transformation(any(), any()) :: none()
  
  defmacro __using__(_) do
    quote do
      @behaviour AppAnimal.Neural.Summarizer
      
      def activate(input) do
        summary = summarize(input)
        describe_transformation(input, summary)
        activate_downstream(summary)
      end

      def describe_transformation(input, summary) do end

      defoverridable activate: 1, describe_transformation: 2
    end
  end
end


  
