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
  alias System.{ActivityLogger}

  typedstruct do
    field :network,         Network.t
    field :p_logger, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

  @impl GenServer
  def handle_call({:accept_network, network}, _from, s_switchboard) do
    s_switchboard
    |> Map.put(:network, network)
    |> continue(returning: :ok)
  end

  @impl GenServer
  def handle_cast({:distribute_pulse, opts}, s_switchboard) do
    cond do
      Keyword.has_key?(opts, :to) ->
        [pulse, destination_names] = Opts.required!(opts, [:carrying, :to])
        Network.deliver_pulse(s_switchboard.network, destination_names, pulse)
        continue(s_switchboard)

      Keyword.has_key?(opts, :from) ->  # recurses to above case
        [pulse, source_name] = Opts.required!(opts, [:carrying, :from])

        source = Network.full_identification(s_switchboard.network, source_name)
        ActivityLogger.log_pulse_sent(s_switchboard.p_logger, source, pulse)
        destination_names =
          Network.destination_names(s_switchboard.network, from: source_name, for: pulse)

        handle_cast({:distribute_pulse, carrying: pulse, to: destination_names},
                    s_switchboard)
    end
  end
end
