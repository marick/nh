alias AppAnimal.Cluster
alias Cluster.OutgoingLogic

defmodule OutgoingLogic do
  @moduledoc """

  Some rather baroque "mkfn" functions that are used to create
  functions that send pulses downstream. They are interfaces of a sort
  to `GenServer.cast`. They have two purposes:

  1. to construct the data structures that embed pulse data in an
     appropriate destination for the destination.

  2. to take a pid and make a function that sends to that pid. By
     encapsulating the pid, client code doesn't have to find it or carry it
     around separately from the function that sends to it.


  """

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
