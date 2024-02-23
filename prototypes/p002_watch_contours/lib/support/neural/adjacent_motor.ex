defmodule AppAnimal.Neural.AdjacentMotor do
  @callback receive_pulse(any()) :: none()
  @callback describe_action(any()) :: none()
  @callback make_action(any()) :: (any() -> none())
  
  defmacro __using__(environment: environment) do
    quote do
      @behaviour AppAnimal.Neural.AdjacentMotor
      
      def receive_pulse(data) do
        describe_action(data)
        action = make_action(data)
        GenServer.cast(unquote(environment), update_with: action)
      end

      def describe_action(data) do end

      defoverridable receive_pulse: 1, describe_action: 1
    end
    
  end
end


  
