defmodule AppAnimal.Neural.LinearCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      require Logger
      alias unquote(switchboard)
      
      def activate_downstream() do
        Switchboard.activate_downstream(__MODULE__)
      end
    end
  end

end
