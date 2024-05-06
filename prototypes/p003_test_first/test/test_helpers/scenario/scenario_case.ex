alias AppAnimal.{Scenario,Extras}

defmodule Scenario.Case do
  defmacro __using__(opts) do
    quote do
      use AppAnimal.Case, unquote(opts)
      use Extras.TestAwareProcessStarter

      import Scenario.ProcessKludgery, only: [animal: 0]
      import Scenario.Configuration
      import Scenario.Provocations

      alias AppAnimal.TestHelpers
      alias AppAnimal.TestHelpers.Animal
      import TestHelpers.{ConnectTestToAnimal,MessageHelpers}
    end
  end
end
