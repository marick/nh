defmodule ClusterCase do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      alias AppAnimal.{System,Network,Cluster}
      alias System.{Switchboard,AffordanceLand,ActivityLogger}
      import ClusterCase.Helpers
      import AppAnimal.ActivityLogAssertions
      use FlowAssertions
      import Cluster.Make
      import Network.ClusterMap
      alias AppAnimal.Duration
      alias AppAnimal.ClusterBuilders, as: C
      alias AppAnimal.NetworkBuilder.Process, as: Add
    end
  end
end
