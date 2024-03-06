defmodule AppAnimal.Neural.ActionEdge do
  use AppAnimal

  defstruct [:name,
             type: :perception_edge,
             act: :installed_by_switchboard
  ]
end
