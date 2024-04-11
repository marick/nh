alias AppAnimal.System
alias System.Network


defmodule System.Switchboard do
  @moduledoc """
  An intermediary between clusters. It receives all sent messages and routes them
  to the downstream clusters.

  By putting the switchboard between clusters, there's a sort of
  centralized control, but one that no cluster code can see. One
  simple use is that the rate of "throbbing" - timer pulses sent to
  circular clusters - can be controlled by tests so that what might
  normally take two seconds happens nearly instantly. Later uses will
  be along the lines of a "chaos monkey": random delays in pulse
  delivery, dropping pulses, rearranging the order of pulses, etc.

  """
  
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias System.{ActivityLogger,Network,Pulse}
  alias AppAnimal.Duration

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :network,    Network.t
    field :throb_interval, integer,        default: Duration.quantum()
    field :p_logger, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

  @doc false
  def l_cluster_named(name), do: l_network() |> Network.l_cluster_named(name)
  @doc false
  def within_network(struct, f), do: deeply_map(struct, :l_network, f)
  
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

    @doc """
    Document the `handle_info` that throbs all active processes.

    When a `Process.send_after` has scheduled a timer that goes off
    and delivers an `info` message, `handle_info(:time_to_throb,...)`
    is called. The `Switchboard` instructs its embedded network to throb all
    active `CircularProcesses`.
    """
    def info__throb_all_active(_p_switchboard), do: :DO_NOT_CALL_FOR_DOCUMENTATION_ONLY

    @doc """
    Document the `handle_info` that handles an exited process.

    When a `CircularProcess` throbs its last, it exits. As the process creator,
    this process receives a `:DOWN` message.

    The embedded network removes the process from the list of known-living processes.
    """
    def info__down(_p_switchboard, {:DOWN, _, :process, _pid, :normal}),
        do:  :DO_NOT_CALL_FOR_DOCUMENTATION_ONLY

  end

  runs_in_receiver do 
    @impl GenServer
    def init(s_switchboard) do
      schedule_next_throb(s_switchboard.throb_interval)
      ok(s_switchboard)
    end

    @impl GenServer
    def handle_call([accept_network: network], _from, s_switchboard) do
      s_switchboard
      |> Map.put(:network, network)
      |> continue(returning: :ok)
    end
    
    # This is used for testing as a way to get internal values of clusters.
    def handle_call([forward: getter_name, to: circular_cluster_name],
                    _from, s_switchboard) do
      result = Network.get_from_cluster(s_switchboard.network, circular_cluster_name, getter_name)
      continue(s_switchboard, returning: result)
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: %Pulse{} = pulse, from: source_name},
                    s_switchboard) do
      source = deeply_get_only(s_switchboard, l_cluster_named(source_name))
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(s_switchboard.p_logger, source.label,
                                    source.name, pulse.data)
      handle_cast({:distribute_pulse, carrying: pulse, to: destination_names},
                  s_switchboard)
    end

    def handle_cast({:distribute_pulse, carrying: %Pulse{} = pulse, to: destination_names},
                    s_switchboard) do
      s_switchboard
      |> within_network(& Network.deliver_pulse(&1, destination_names, pulse))
      |> continue
    end
    
    @impl GenServer
    def handle_info(:time_to_throb, s_switchboard) do
      Network.Throb.time_to_throb(s_switchboard.network)
      schedule_next_throb(s_switchboard.throb_interval)
      continue(s_switchboard)
    end

    def handle_info({:DOWN, _, :process, pid, :normal}, s_switchboard) do
      s_switchboard
      |> within_network(& Network.Throb.pid_has_aged_out(&1, pid))
      |> continue
    end
    
    private do
      def schedule_next_throb(pulse_delay) do
        Process.send_after(self(), :time_to_throb, pulse_delay)
      end
    end
  end
end
