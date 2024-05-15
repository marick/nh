defmodule AppAnimal.KeyConceptAliases do
  defmacro __using__(_) do
    quote do
      alias AppAnimal.{Cluster,System,Network,ActivityLogger}
      alias System.{Switchboard,AffordanceLand}
      alias Cluster.{Throb,Identification}
    end
  end
end
