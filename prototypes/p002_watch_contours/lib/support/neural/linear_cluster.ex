defmodule AppAnimal.Neural.LinearCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      require Logger
      alias unquote(switchboard)
      
      def activate_downstream(small_data) do
        Switchboard.activate_downstream(__MODULE__, small_data)
      end
    end
  end

end
