defmodule AppAnimal.NeuralCluster do
  alias AppAnimal.PrettyModule

  
  defmacro __using__(_args) do
    quote do
      defp verbify() do
        case @mechanism do
          :flow_emulator -> "checks"
          :gate -> "gates"
        end
      end
      
      def describe() do
        "#{inspect @mechanism} #{PrettyModule.minimal __MODULE__} " <>
          "#{verbify()} #{PrettyModule.minimal @upstream}, " <>
          "sends to #{PrettyModule.minimal @downstream}"
      end
    end
  end
end
