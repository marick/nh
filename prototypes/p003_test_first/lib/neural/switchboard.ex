defmodule AppAnimal.Neural.Switchboard do
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias Neural.ActivityLogger
  alias AppAnimal.Neural.Network

  @type process_map :: %{atom => pid}

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :network,    Network.t
    field :pulse_rate, integer,          default: 100  # in milliseconds
    field :logger_pid, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

  def l_cluster_named(name),
      do: l_network() |> Network.l_cluster_named(name)

  def within_network(struct, f), do: deeply_map(struct, :l_network, f)
  
  runs_in_sender do
    # I'd rather not have this layer of indirection, but it's needed for tests to use
    # start_supervised.
    def start_link(%__MODULE__{} = state) do
      GenServer.start_link(__MODULE__, state)
    end
  end

  runs_in_receiver do 
    @impl GenServer
    def init(mutable) do
      schedule_next_throb(mutable.pulse_rate)
      ok(mutable)
    end

    @impl GenServer
    def handle_call({:link_clusters_to_architecture, switchboard_pid, affordances_pid},
                    _from, mutable) do

      mutable
      |> within_network(& Network.link_clusters_to_architecture(&1,
                                                                switchboard_pid,
                                                                affordances_pid))
      |> continue(returning: :ok)
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable) do
      mutable
      |> within_network(& Network.deliver_pulse(&1, destination_names, pulse_data))
      |> continue
    end

    def handle_cast({:distribute_pulse, carrying: pulse_data, from: source_name},
                    mutable) do
      source = deeply_get_only(mutable, l_cluster_named(source_name))
      
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(mutable.logger_pid, source.label, source.name, pulse_data)
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable)
    end

    @impl GenServer
    def handle_info(:time_to_throb, mutable) do
      Network.time_to_throb(mutable.network)
      schedule_next_throb(mutable.pulse_rate)
      continue(mutable)
    end

    def handle_info({:DOWN, _, :process, pid, :normal}, mutable) do
      mutable
      |> within_network(& Network.drop_idling_pid(&1, pid))
      |> continue
    end
    
    private do
      def schedule_next_throb(pulse_delay) do
        Process.send_after(self(), :time_to_throb, pulse_delay)
      end
    end
  end
end
