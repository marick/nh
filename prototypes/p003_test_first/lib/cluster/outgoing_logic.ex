alias AppAnimal.Cluster
alias Cluster.OutgoingLogic

defmodule OutgoingLogic do 

  def mkfn_pulse_direction(:internal, name) do
    f_pid_taker = 
      fn pid ->
        fn pulse_data -> 
          payload = {:distribute_pulse, carrying: pulse_data, from: name}
          GenServer.cast(pid, payload)
        end
      end
    {:internal, f_pid_taker}
  end
  
  def mkfn_pulse_direction(:external) do
    f_pid_taker = 
      fn pid ->
        fn pulse_data -> 
          GenServer.cast(pid, [:note_action, pulse_data])
        end
      end
    {:external, f_pid_taker}
  end
end
