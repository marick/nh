defmodule ClusterCase do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use FlowAssertions

      alias AppAnimal.{System,Network,Cluster,Extras}
      alias System.{Switchboard,AffordanceLand,ActivityLogger}

      use Extras.TestAwareProcessStarter

      import ClusterCase.Helpers
      import AppAnimal.ActivityLogAssertions

      import Cluster.Make
      import Network.ClusterMap                          ### delete

      alias AppAnimal.Duration
      alias AppAnimal.ClusterBuilders, as: C
      alias AppAnimal.NetworkBuilder
    end
  end
end
