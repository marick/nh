defmodule AppAnimal.Neural.NetworkNode do
  defstruct [:module, downstream: [], configuration: %{}]
end
