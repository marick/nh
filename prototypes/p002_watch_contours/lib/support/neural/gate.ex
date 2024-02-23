defmodule AppAnimal.Neural.Gate do
  @callback should_send_pulse?(any()) :: boolean()
  @callback description_of_check(any()) :: String.t
  @callback receive_pulse(any()) :: none()
  @callback outgoing_data(any()) :: any()
  
  defmacro __using__(_) do
    quote do
      @behaviour AppAnimal.Neural.Gate

      def description_of_check(_upstream_data) do
        :none
      end
      
      def receive_pulse(upstream_data) do
        passes? = should_send_pulse?(upstream_data)
        
        case {description_of_check(upstream_data), passes?} do
          {:none, _} ->
            :ok
          {description, true} ->
            Logger.info(description <> " -- (yes)")
          {description, false} ->
            Logger.info(description <> " -- (no: pathway done)")
        end
        
        if passes? do
          payload = outgoing_data(upstream_data)
          send_pulse(payload)
        end
      end

      def outgoing_data(_upstream_data) do
        :ok
      end
      defoverridable receive_pulse: 1, description_of_check: 1, outgoing_data: 1
    end
    
  end
end


  
