defmodule AppAnimal.Case do
  defmacro __using__(opts) do
    quote do
      use ExUnit.Case, unquote(opts)
      use AppAnimal
      use FlowAssertions
      import FlowAssertions.TabularA

      alias AppAnimal.{System,Network,Cluster,Extras}
      alias System.{Switchboard,AffordanceLand,ActivityLogger}

      import AppAnimal.ActivityLogAssertions
      alias AppAnimal.Duration
      alias AppAnimal.ClusterBuilders, as: C
    end
  end
end