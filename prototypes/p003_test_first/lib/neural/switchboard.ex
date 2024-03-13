defmodule AppAnimal.Neural.Switchboard do
  use AppAnimal
  use AppAnimal.GenServer
  alias Neural.ActivityLogger

  defstruct [:network,
             started_circular_clusters: %{},
             pulse_rate: 100,
             logger_pid: ActivityLogger.start_link |> okval]

  runs_in_sender do
    def start_link(%__MODULE__{} = state) do
      GenServer.start_link(__MODULE__, state)
    end

    def link_clusters_to_pids(switchboard_pid, affordances_pid) do
      GenServer.call(switchboard_pid,
                     {:individualize_pulses, switchboard_pid, affordances_pid})
    end
    
    # An entry point, called to initiate or reinitiate a network.
    def external_pulse(switchboard_pid, to: destination_name, carrying: pulse_data) do
      GenServer.cast(switchboard_pid,
                     {:distribute_pulse, carrying: pulse_data, to: [destination_name]})
    end

    def send_pulse_downstream(switchboard_pid, from: source_name, carrying: pulse_data) do
      GenServer.cast(switchboard_pid,
                     {:distribute_downstream, from: source_name, carrying: pulse_data})
    end

    def forward_affordance(switchboard_pid, named: name, conveying: perception) do
      external_pulse(switchboard_pid, to: name, carrying: perception)
    end
  end

  runs_in_receiver do 
    @impl GenServer
    def init(mutable) do
      schedule_weakening(mutable.pulse_rate)
      ok(mutable)
    end

    @impl GenServer
    def handle_call({:individualize_pulses, switchboard_pid, affordances_pid},
                    _from, mutable) do
      add_individualized_pulse = fn cluster -> 
        AppAnimal.Cluster.Variations.install_pulse_sender(cluster, {switchboard_pid, affordances_pid})
      end

      mutable
      |> Map2.map_within(:network, add_individualized_pulse)
      |> continue(returning: :ok)
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable) do
      mutable
      |> ensure_clusters_are_ready(destination_names)
      |> tap(& send_pulse(pulse_data, destination_names, &1))
      |> continue
    end

    def handle_cast({:distribute_downstream, from: source_name, carrying: pulse_data}, mutable) do
      source = mutable.network[source_name]
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(mutable.logger_pid, source.label, source.name, pulse_data)
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable)
    end

    @impl GenServer
    def handle_info(:weaken_all_active, mutable) do
      for {_name, pid} <- mutable.started_circular_clusters do
        GenServer.cast(pid, [weaken: 1])
      end
      schedule_weakening(mutable.pulse_rate)
      continue(mutable)
    end

    def handle_info({:DOWN, _, :process, pid, :normal}, mutable) do
      mutable
      |> Map2.reject_value_within(:started_circular_clusters, pid)
      |> continue
    end
    
    private do
      def ensure_clusters_are_ready(mutable, names) do
        ensure_one_name = fn name, acc ->
          cluster = mutable.network[name]
          AppAnimal.Cluster.Variations.Topology.ensure_ready(cluster.topology, cluster, acc) 
        end
        
        names
        |> Enum.reduce(mutable.started_circular_clusters, ensure_one_name)
        |> then(& put_in(mutable.started_circular_clusters, &1))
      end

      def send_pulse(pulse_data, names, mutable) do
        for name <- names do
          pid = mutable.started_circular_clusters[name]
          cluster = mutable.network[name]
          AppAnimal.Cluster.Variations.Topology.generic_pulse(cluster.topology, cluster, pid, pulse_data)
        end
      end

      def schedule_weakening(pulse_delay) do
        Process.send_after(self(), :weaken_all_active, pulse_delay)
      end
    end
  end
end
