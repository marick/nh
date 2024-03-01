defmodule AppAnimal.Neural.AffordanceLand do
  use AppAnimal
  use AppAnimal.GenServer 

  runs_in_sender do
    def start_link([switchboard: switchboard]) do
      GenServer.start_link(__MODULE__, switchboard)
    end

    def provide_affordance(me, named: affordance_name, conveying: data) do
      GenServer.cast(me, {:affordance, affordance_name, data})
    end
  end

  runs_in_receiver do
    def init(state) do
      {:ok, state}
    end

    def handle_cast({:affordance, affordance_name, data}, switchboard_pid) do
      Neural.Switchboard.forward_affordance(switchboard_pid,
                                            named: affordance_name, conveying: data)
      continue(switchboard_pid)
    end
  end
  
end
