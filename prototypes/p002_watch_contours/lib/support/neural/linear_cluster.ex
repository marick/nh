defmodule AppAnimal.Neural.LinearCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      require Logger
      alias unquote(switchboard)
      
      def activate_downstream(small_data) do
        message = [transmit: small_data, to_downstream_of: __MODULE__]
        GenServer.cast(unquote(switchboard), message)
      end
    end
  end
end
