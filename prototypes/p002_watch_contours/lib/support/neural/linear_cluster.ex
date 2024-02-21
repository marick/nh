defmodule AppAnimal.Neural.LinearCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      def start_appropriately(small_data) do
        runner = fn -> apply(__MODULE__, :activate, [small_data]) end
        Task.start(runner)
      end
      
      def activate_downstream(small_data) do
        message = [transmit: small_data, to_downstream_of: __MODULE__]
        GenServer.cast(unquote(switchboard), message)
        :receives_no_more_messages
      end
    end
  end
end
