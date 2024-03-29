defmodule AppAnimal.Neural.CircularCluster do
  
  defmacro __using__(switchboard: switchboard) do
    quote do
      def start_appropriately(small_data) do
        {:ok, pid} = GenServer.start_link(__MODULE__, small_data)
        [monitor: pid]
      end
      
      def send_pulse(small_data) do
        message = [transmit: small_data, to_downstream_of: __MODULE__]
        GenServer.cast(unquote(switchboard), message)
      end
    end
  end
end
