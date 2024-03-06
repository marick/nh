defmodule AppAnimal.Neural.Switchboard do
  use AppAnimal
  use AppAnimal.GenServer
  alias Neural.ActivityLogger

  defstruct [:network,
             started_circular_clusters: %{},
             pulse_rate: 100,
             logger: :set_at_start_link_time]

  runs_in_sender do
    def start_link(%__MODULE__{} = state) do
      GenServer.start_link(__MODULE__, state)
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
      send_pulse_downstream(switchboard_pid, from: name, carrying: perception)
    end

    def spill_log_to_terminal(switchboard_pid) do
      GenServer.cast(switchboard_pid, [spill_log_to_terminal: true])
    end

    def silence_terminal_log(switchboard_pid) do
      GenServer.cast(switchboard_pid, [spill_log_to_terminal: false])
    end

    def get_log(switchboard_pid) do
      GenServer.call(switchboard_pid, :get_log)
    end

    def get_logger_pid(switchboard_pid) do
      GenServer.call(switchboard_pid, :get_logger_pid)
    end
  end

  runs_in_receiver do 
    @impl GenServer
    def init(me) do
      schedule_weakening(me.pulse_rate)

      add_individualized_pulses = fn cluster ->
        sending_function = mkfn__individualized_pulse_downstream(cluster.name)
        %{cluster | send_pulse_downstream: sending_function}
      end

      {:ok, logger} = ActivityLogger.start_link

      me
      |> Map2.map_within(:network, add_individualized_pulses)
      |> Map.put(:logger, logger)
      |> ok()
    end

    @impl GenServer
    def handle_call(:get_log, _from, me), 
        do: continue(me, returning: ActivityLogger.get_log(me.logger))

    def handle_call(:get_logger_pid, _from, me), 
        do: continue(me, returning: me.logger)

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me) do
      %{linear: linear_names, circular: circular_names} =
        separate_by_cluster_type(destination_names, given: me.network)
      
      new_me = ensure_circular_clusters_are_ready(circular_names, me)
      pulse_to_circular(pulse_data, circular_names, new_me)
      pulse_to_linear(pulse_data, linear_names, new_me)
      
      continue(new_me)
    end

    def handle_cast({:distribute_downstream, from: source_name, carrying: pulse_data}, me) do
      source = me.network[source_name]
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(me.logger, source.type, source.name, pulse_data)
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me)
    end

    def handle_cast([spill_log_to_terminal: value], me) do
      ActivityLogger.spill_log_to_terminal(me.logger, value)
      continue(me)
    end

    @impl GenServer
    def handle_info(:weaken_all_active, me) do
      for {_name, pid} <- me.started_circular_clusters do
        GenServer.cast(pid, [weaken: 1])
      end
      schedule_weakening(me.pulse_rate)
      continue(me)
    end

    def handle_info({:DOWN, _, :process, pid, :normal}, me) do
      me
      |> Map2.reject_value_within(:started_circular_clusters, pid)
      |> continue()
    end

    
    private do
      def mkfn__individualized_pulse_downstream(source_name) do
        my_pid = self()
        fn carrying: pulse_data ->
          payload = {:distribute_downstream, from: source_name, carrying: pulse_data}
          GenServer.cast(my_pid, payload)
        end
      end

      def separate_by_cluster_type(names, given: network) do
        {linears, circulars} =
          names
          |> Enum.split_with(fn name ->
            is_struct(Map.fetch!(network, name), Neural.LinearCluster)
          end)

        %{linear: linears, circular: circulars}
      end

      def ensure_circular_clusters_are_ready(names, me) do
        already_started = me.started_circular_clusters

        next_started = 
          names
          |> Enum.reject(&(Map.has_key?(already_started, &1)))
          |> Enum.reduce(already_started, fn name, acc ->
            configuration = me.network[name]
            {:ok, pid} = GenServer.start(configuration.__struct__, configuration)
            Process.monitor(pid)
            Map.put(acc, name, pid)
          end)

        %{me | started_circular_clusters: next_started}
      end

      def pulse_to_circular(pulse_data, circular_names, me) do
        for name <- circular_names do
          destination_pid = me.started_circular_clusters[name]
          GenServer.cast(destination_pid, [handle_pulse: pulse_data])
        end
        :ok
      end

      def pulse_to_linear(pulse_data, linear_names, me) do
        for name <- linear_names do
          config = me.network[name]
          Task.start(fn ->
            config.handlers.handle_pulse.(pulse_data, config)
          end)
        end
      end

      def schedule_weakening(pulse_delay) do
        Process.send_after(self(), :weaken_all_active, pulse_delay)
      end
    end
  end
end
