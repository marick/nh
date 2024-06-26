defmodule AppAnimal.KeyConceptAliases do
  defmacro __using__(_) do
    quote do
      alias AppAnimal.{Cluster,Moveable,Network,ActivityLogger}
      alias AppAnimal.{Switchboard,AffordanceLand}
      alias Cluster.{Throb,Identification}
    end
  end
end
