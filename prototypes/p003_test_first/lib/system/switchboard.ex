alias AppAnimal.{System,Network}

defmodule System.Switchboard do
  @moduledoc """
  An intermediary between clusters. It receives all sent messages and routes them
  to the downstream clusters.

  Originally, this had to be a process because it controlled "throbbing". It no longer
  maintains any mutable state, so it could be a plain module. However, I might want to
  play "chaos monkey" games - dropping pulses and so on - so I won't bother changing it.
  """

  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias System.{ActivityLogger,Pulse}

  typedstruct do
    field :network,         Network.t
    field :p_logger, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

  runs_in_receiver do
    @impl GenServer
    def init(s_switchboard) do
      ok(s_switchboard)
    end

    @impl GenServer
    def handle_call([accept_network: network], _from, s_switchboard) do
      s_switchboard
      |> Map.put(:network, network)
      |> continue(returning: :ok)
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: %Pulse{} = pulse, from: source_name},
                    s_switchboard) do
      source = Network.full_identification(s_switchboard.network, source_name)
      ActivityLogger.log_pulse_sent(s_switchboard.p_logger, source, pulse)
      destination_names =
        Network.destination_names(s_switchboard.network, from: source_name, for: pulse)

      handle_cast({:distribute_pulse, carrying: pulse, to: destination_names},
                  s_switchboard)
    end

    def handle_cast({:distribute_pulse, carrying: %Pulse{} = pulse, to: destination_names},
                    s_switchboard) do

      Network.deliver_pulse(s_switchboard.network, destination_names, pulse)
      continue(s_switchboard)
    end
  end
end
