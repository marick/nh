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
    plugin TypedStructLens, prefix: :l_

    field :network,         Network.t
    field :p_logger, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

  @doc false
  def l_cluster_named(name), do: l_network() |> Network.l_cluster_named(name)
  
  runs_in_sender do
    # I'd rather not have this layer of indirection, but it's needed for tests to use
    # start_supervised.
    def start_link(%__MODULE__{} = s_switchboard),
        do: GenServer.start_link(__MODULE__, s_switchboard)

    @doc """
    Send a pulse to a set of clusters.

    There are two variants. You can say the pulse comes *from:* a cluster, in which
    case the pulse is delivered to that cluster's downstream. Or the pulse can be
    delivered `to:` a list of names.

    In either case, clusters are identified by their atom names.

    Examples:
        cast__distribute_pulse(p_switchboard, carrying: pulse_data, from: source_name)
        cast__distribute_pulse(p_switchboard, carrying: pulse_data, to: destination_names)
    
    """
    def cast__distribute_pulse(p_switchboard, one_of_two_keyword_lists)
    def cast__distribute_pulse(p_switchboard, carrying: %Pulse{} = pulse, from: source_name),
        do: GenServer.cast(p_switchboard,
                           {:distribute_pulse, carrying: pulse, from: source_name})

    def cast__distribute_pulse(p_switchboard, carrying: %Pulse{} = pulse, to: destination_names),
        do: GenServer.cast(p_switchboard,
                           {:distribute_pulse, carrying: pulse, to: destination_names})
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
      source = Network.name_to_cluster(s_switchboard.network, source_name)
      destination_names = Network.downstream_of(s_switchboard.network, source_name)
      ActivityLogger.log_pulse_sent(s_switchboard.p_logger, source.label,
                                    source.name, pulse.data)
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
