alias AppAnimal.System
alias AppAnimal.System.Network


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
  alias System.ActivityLogger
  alias System.Network
  import AppAnimal.Clock

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :network,    Network.t
    field :throb_rate, integer,        default: default_rate()
    field :p_logger, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

  def l_cluster_named(name), do: l_network() |> Network.l_cluster_named(name)
  
  def within_network(struct, f), do: deeply_map(struct, :l_network, f)
  
  runs_in_sender do
    # I'd rather not have this layer of indirection, but it's needed for tests to use
    # start_supervised.
    def start_link(%__MODULE__{} = s_switchboard),
        do: GenServer.start_link(__MODULE__, s_switchboard)
  end

  runs_in_receiver do 
    @impl GenServer
    def init(s_switchboard) do
      schedule_next_throb(s_switchboard.throb_rate)
      ok(s_switchboard)
    end

    ## Once a network of clusters is built, this call instructs each
    ## cluster to construct an appropriate sending function that goes to
    ## either the Switchboard or Affordance Land.
    @impl GenServer
    def handle_call({:link_clusters_to_architecture, p_switchboard, p_affordances},
                    _from, s_switchboard) do

      s_switchboard
      |> within_network(& Network.Make.link_clusters_to_architecture(&1,
                                                                     p_switchboard,
                                                                     p_affordances))
      |> continue(returning: :ok)
    end

    def handle_call([forward: message, to: circular_cluster_name],
                    _from, s_switchboard) do
      dbg s_switchboard
      pid = deeply_get_only(s_switchboard.network, Network.l_pid_named(circular_cluster_name)) |> dbg
      result = GenServer.call(pid, message) |> dbg
      continue(s_switchboard, returning: result)
    end
    
    ## The main entry point to send a pulse from the `source_name` to the named
    ## cluster's downstream.
    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, from: source_name},
                    s_switchboard) do
      source = deeply_get_only(s_switchboard, l_cluster_named(source_name))
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(s_switchboard.p_logger, source.label,
                                    source.name, pulse_data)
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names},
                  s_switchboard)
    end

    ## Deliver a pulse to some downstream names.
    ## 
    ## Used by `AffordanceLand` and in tests. A helper helper function for delivering
    ## from a known name to its downstream.
    ## 
    ## Note this affects the `s_switchboard` state because pulse delivery may start
    ## circular clusters (genservers).
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names},
                    s_switchboard) do
      s_switchboard
      |> within_network(& Network.deliver_pulse(&1, destination_names, pulse_data))
      |> continue
    end

    ## Deliver a "throb" message to all circular clusters.
    ## 
    ## Essentially a global clock tick, mostly to cause running clusters
    ## to age out and exit.
    @impl GenServer
    def handle_info(:time_to_throb, s_switchboard) do
      Network.Throb.time_to_throb(s_switchboard.network)
      schedule_next_throb(s_switchboard.throb_rate)
      continue(s_switchboard)
    end

    ## Called by the runtime when a circular cluster exits.
    ##
    ## This means it should be removed from the list of clusters sent
    ## messages that cause them to "throb".
    def handle_info({:DOWN, _, :process, pid, :normal}, s_switchboard) do
      s_switchboard
      |> within_network(& Network.Throb.drop_idling_pid(&1, pid))
      |> continue
    end
    
    private do
      def schedule_next_throb(pulse_delay) do
        Process.send_after(self(), :time_to_throb, pulse_delay)
      end
    end
  end
end
