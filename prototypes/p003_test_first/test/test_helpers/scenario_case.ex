defmodule ScenarioCase do

  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use FlowAssertions

      alias AppAnimal.{System,Network,Extras}
      alias System.{Switchboard,AffordanceLand,ActivityLogger}

      use Extras.TestAwareProcessStarter

      import ScenarioCase.Helpers
      import AppAnimal.ActivityLogAssertions

      alias AppAnimal.Duration
      alias AppAnimal.ClusterBuilders, as: C
    end
  end
end
