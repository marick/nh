defmodule AppAnimal.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use AppAnimal.KeyConceptAliases
      use FlowAssertions
      import FlowAssertions.TabularA
      import AppAnimal.ActivityLogAssertions
      import AppAnimal.TestHelpers.MessageHelpers
      alias AppAnimal.ClusterBuilders, as: C
    end
  end
end
