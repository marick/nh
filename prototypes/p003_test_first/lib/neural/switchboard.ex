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

      add_individualized_pulse = fn cluster -> 
        Neural.Clusterish.install_pulse_sender(cluster, {self(), :ok})
      end

      me
      |> Map2.map_within(:network, add_individualized_pulse)
      |> Map.put(:logger, ActivityLogger.start_link |> okval)
      |> ok
    end

    @impl GenServer
    def handle_call(:get_log, _from, me), 
        do: continue(me, returning: ActivityLogger.get_log(me.logger))

    def handle_call(:get_logger_pid, _from, me), 
        do: continue(me, returning: me.logger)

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me) do
      me
      |> ensure_clusters_are_ready(destination_names)
      |> tap(& send_pulse(pulse_data, destination_names, &1))
      |> continue
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
      |> continue
    end
    
    private do
      def ensure_clusters_are_ready(me, names) do
        ensure_one_name = fn name, acc ->
          Neural.Clusterish.ensure_ready(me.network[name], acc) 
        end

        names
        |> Enum.reduce(me.started_circular_clusters, ensure_one_name)
        |> then(& put_in(me.started_circular_clusters, &1))
      end

      def send_pulse(pulse_data, names, me) do
        for name <- names do
          case Map.has_key?(me.started_circular_clusters, name) do
            true ->
              destination_pid = me.started_circular_clusters[name]
              GenServer.cast(destination_pid, [handle_pulse: pulse_data])
            false ->
              config = me.network[name]
              Task.start(fn ->
                config.handlers.handle_pulse.(pulse_data, config)
              end)
          end
        end
      end

      def schedule_weakening(pulse_delay) do
        Process.send_after(self(), :weaken_all_active, pulse_delay)
      end
    end
  end
end
