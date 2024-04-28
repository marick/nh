alias AppAnimal.{TestHelpers,Extras,Scenario}

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

      import TestHelpers.ProcessKludgery, only: [animal: 0]
      import TestHelpers.ScenarioBuilding
      import TestHelpers.ScenarioProvocations
      import TestHelpers.ConnectTestToAnimal
      import AppAnimal.ActivityLogAssertions

      alias AppAnimal.ClusterBuilders, as: C
    end
  end
end
