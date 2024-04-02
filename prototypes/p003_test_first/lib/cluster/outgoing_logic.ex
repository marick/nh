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

  alias AppAnimal.System.{Switchboard, AffordanceLand, Pulse}

  def mkfn_pulse_direction(Switchboard, name) do
    f_pid_taker = 
      fn pid ->
        fn pulse ->
          Switchboard.cast__distribute_pulse(pid, carrying: pulse, from: name)
        end
      end
    {Switchboard, f_pid_taker}
  end
  
  def mkfn_pulse_direction(AffordanceLand) do
    f_pid_taker = 
      fn pid ->
        fn %Pulse{data: pulse_data} ->
          # Pulses into affordance land are not wrapped in Pulses.
          # The idea is that Affordance Land shouldn't be talked about in terms
          # of neural pulses. Alternately, the pulse is received by motor neurons
          # that converts it into actions.
          GenServer.cast(pid, [:take_action, pulse_data])
        end
      end
    {AffordanceLand, f_pid_taker}
  end
end
