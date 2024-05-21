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

    def handle_cast({:on_behalf_of, originating_cluster_name, deliver: pulse}, s_switchboard) do
      full_id =
        s_switchboard.network
        |> A.one!(Network.id_for(originating_cluster_name))

      ActivityLogger.log_pulse_sent(s_switchboard.p_logger, full_id, pulse)
      downstream =
        s_switchboard.network
        |> A.one!(Network.downstream(from: originating_cluster_name, for: pulse))

      Network.deliver_pulse(s_switchboard.network, downstream, pulse)
      continue(s_switchboard)
    end

    def handle_cast({:fan_out, pulse, to: downstream}, s_switchboard) do
      Network.deliver_pulse(s_switchboard.network, downstream, pulse)
      continue(s_switchboard)
    end

    def handle_cast({:distribute_pulse, opts}, s_switchboard) do
      cond do
        Keyword.has_key?(opts, :to) ->
          cast_to_N(s_switchboard, opts)
      end
      continue(s_switchboard)
    end

    defp cast_to_N(s_switchboard, opts) do
      [pulse, downstream] = Opts.required!(opts, [:carrying, :to])
      Network.deliver_pulse(s_switchboard.network, downstream, pulse)
    end
  end
end
