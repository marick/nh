defmodule AppAnimal.Neural.Switchboard do
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias Neural.ActivityLogger
  alias AppAnimal.Cluster

  @type process_map :: %{atom => pid}

  typedstruct do
    plugin TypedStructLens, prefix: :_

    field :network, %{atom => Cluster.t}
    field :started_circular_clusters, process_map, default: %{}
    field :pulse_rate, integer, default: 100
    field :logger_pid, ActivityLogger.t, default: ActivityLogger.start_link |> okval
  end

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
        cluster
        |> Map.update!(:pulse_logic, & Cluster.PulseLogic.put_pid(&1, {switchboard_pid, affordances_pid}))
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
      source = mutable.network[source_name] # |> IO.inspect
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(mutable.logger_pid, source.label, source.name, pulse_data)
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable)
    end

    @impl GenServer
    def handle_info(:weaken_all_active, mutable) do
      for {_name, pid} <- started_circular_clusters(mutable) do
        GenServer.cast(pid, [weaken: 1])
      end
      schedule_weakening(mutable.pulse_rate)
      continue(mutable)
    end

    def handle_info({:DOWN, _, :process, pid, :normal}, mutable) do
      mutable
      |> unstart_circular_cluster(pid)
      |> continue
    end
    
    private do
      def started_circular_clusters(mutable) do
        mutable.started_circular_clusters
      end

      def unstart_circular_cluster(mutable, pid) do
        mutable 
        |> Map2.reject_value_within(:started_circular_clusters, pid)        
      end
      
      def ensure_clusters_are_ready(mutable, names) do
        lens = _network() |> Lens.keys!(names) |> Lens.filter(&Cluster.can_be_active?/1)

        startable = deeply_get_all(mutable, lens)
        unstarted = Enum.reject(startable, & &1.name in Map.keys(mutable.started_circular_clusters))
        now_started =
          for cluster <- unstarted, into: %{} do
            Cluster.activate(cluster)
          end

        all_started = Map.merge(mutable.started_circular_clusters, now_started)
        %{mutable | started_circular_clusters: all_started}
      end

      def send_pulse(pulse_data, names, mutable) do
        for name <- names do
          pid = started_circular_clusters(mutable)[name]
          cluster = mutable.network[name]
          Cluster.Shape.accept_pulse(cluster.shape, cluster, pid, pulse_data)
        end
      end

      def schedule_weakening(pulse_delay) do
        Process.send_after(self(), :weaken_all_active, pulse_delay)
      end
    end
  end
end
