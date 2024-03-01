defmodule AppAnimal.Neural.AffordanceLand do
  use AppAnimal
  use AppAnimal.GenServer 

  runs_in_sender do
    def start_link(script) do
      GenServer.start_link(__MODULE__, script)
    end
    
  end

  runs_in_receiver do
    def init(script) do
      {:ok, script}
    end
  end
  
end
