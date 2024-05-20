alias AppAnimal

defmodule AppAnimal.Switchboard do
  @moduledoc """
  An intermediary between clusters. It receives all sent messages and routes them
  to the downstream clusters.

  Originally, this had to be a process because it controlled "throbbing". It no longer
  maintains any mutable state, so it could be a plain module. However, I might want to
  play "chaos monkey" games - dropping pulses and so on - so I won't bother changing it.
  """

  use AppAnimal
  use KeyConceptAliases
  use AppAnimal.StructServer

  typedstruct enforce: true do
    field :network,         Network.t
    field :p_logger, ActivityLogger.t
  end


  handle_CALL do
    def handle_call({:accept_network, network}, _from, s_switchboard) do
      s_switchboard
      |> Map.put(:network, network)
      |> continue(returning: :ok)
    end
  end


  handle_CAST do
    def handle_cast({:distribute_pulse, opts}, s_switchboard) do
      cond do
        Keyword.has_key?(opts, :to) ->
          cast_to_N(s_switchboard, opts)

        Keyword.has_key?(opts, :from) ->
          convert_opts_to_use(:to, s_switchboard, opts)
          |> then(& cast_to_N(s_switchboard, &1))
      end
      continue(s_switchboard)
    end

    defp cast_to_N(s_switchboard, opts) do
      [pulse, destination_names] = Opts.required!(opts, [:carrying, :to])
      Network.deliver_pulse(s_switchboard.network, destination_names, pulse)
    end

    defp convert_opts_to_use(:to, s_switchboard, opts) do
      [pulse, source_name] = Opts.required!(opts, [:carrying, :from])

      full_id =
        s_switchboard.network
        |> A.one!(Network.id_for(source_name))

      ActivityLogger.log_pulse_sent(s_switchboard.p_logger, full_id, pulse)
      destination_names =
        Network.destination_names(s_switchboard.network, from: source_name, for: pulse)
      [carrying: pulse, to: destination_names]
    end
  end
end
