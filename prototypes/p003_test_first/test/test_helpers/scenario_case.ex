defmodule ScenarioCase do

  defmacro __using__(opts) do
    quote do
      alias AppAnimal.{System,Network,Extras}
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use FlowAssertions
      use Extras.TestAwareProcessStarter
      alias System.{Switchboard,AffordanceLand,ActivityLogger}
      require ScenarioCase.Helpers
      import ScenarioCase.Helpers
      import AppAnimal.ActivityLogAssertions
      alias AppAnimal.Duration
      alias AppAnimal.ClusterBuilders, as: C
      alias AppAnimal.NetworkBuilder.Process, as: Add
    end
  end
end
