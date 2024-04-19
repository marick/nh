alias AppAnimal.{Building,Network}

defmodule Building.Whole do
  use AppAnimal
  use AppAnimal.GenServer

  runs_in_sender do 
    def start_link(_) do
      GenServer.start_link(__MODULE__, Network.empty)
    end
  end

  runs_in_receiver do
    def init(network) do
      ok(network)
    end
  end
end
