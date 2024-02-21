defmodule AppAnimal.Neural.CircularCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      def start_appropriately(small_data) do
        GenServer.start_link(__MODULE__, small_data)
      end
      
      def activate_downstream(small_data) do
        message = [transmit: small_data, to_downstream_of: __MODULE__]
        GenServer.cast(unquote(switchboard), message)
      end
    end
  end
end
