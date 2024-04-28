alias AppAnimal.{Scenario,Extras}

defmodule Scenario.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use FlowAssertions
      use Extras.TestAwareProcessStarter

      # Universal enough to make top-level
      alias AppAnimal.{System,Network,Extras,Duration}
      alias System.{Switchboard,AffordanceLand,ActivityLogger}
      alias AppAnimal.Scenario

      import Scenario.ProcessKludgery, only: [animal: 0]
      import Scenario.Configuration
      import Scenario.Provocations
      import AppAnimal.TestHelpers.ConnectTestToAnimal
      import AppAnimal.ActivityLogAssertions

      alias AppAnimal.ClusterBuilders, as: C
    end
  end
end
