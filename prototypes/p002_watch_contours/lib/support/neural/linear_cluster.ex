defmodule AppAnimal.Neural.LinearCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      require Logger
      alias unquote(switchboard)
      
      def activate_downstream() do
        Switchboard.activate_downstream(__MODULE__)
      end

      def activate_downstream(transmitting: small_data) do
        Switchboard.activate_downstream(__MODULE__, transmitting: small_data)
      end
    end
  end

end
