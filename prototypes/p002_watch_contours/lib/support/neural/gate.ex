defmodule AppAnimal.Neural.Gate do
  @callback activate_downstream?(any()) :: boolean()
  @callback description_of_check(any()) :: String.t
  @callback activate(any()) :: none()
  @callback downstream_data(any()) :: any()
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      use AppAnimal.Neural.LinearCluster, switchboard: unquote(switchboard)
      @behaviour AppAnimal.Neural.Gate

      def description_of_check(_upstream_data) do
        :none
      end
      
      def activate(upstream_data) do
        passes? = activate_downstream?(upstream_data)
        
        case {description_of_check(upstream_data), passes?} do
          {:none, _} ->
            :ok
          {description, true} ->
            Logger.info(description <> " -- (yes)")
          {description, false} ->
            Logger.info(description <> " -- (no: pathway done)")
        end
        
        if passes? do
          payload = downstream_data(upstream_data)
          activate_downstream(payload)
        end
      end

      def downstream_data(_upstream_data) do
        :ok
      end
      defoverridable activate: 1, description_of_check: 1, downstream_data: 1
    end
    
  end
end


  
