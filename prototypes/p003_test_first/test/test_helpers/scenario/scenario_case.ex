alias AppAnimal.{Scenario,Extras,TestHelpers}

defmodule Scenario.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use AppAnimal.KeyConceptAliases
      use FlowAssertions
      use Extras.TestAwareProcessStarter

      alias AppAnimal.Scenario

      import Scenario.ProcessKludgery, only: [animal: 0]
      import Scenario.Configuration
      import Scenario.Provocations

      import TestHelpers.ConnectTestToAnimal
      import AppAnimal.TestHelpers.MessageHelpers
      alias TestHelpers.Animal

      import AppAnimal.ActivityLogAssertions

      alias AppAnimal.ClusterBuilders, as: C
    end
  end
end
