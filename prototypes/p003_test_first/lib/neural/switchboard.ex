defmodule AppAnimal.Neural.Switchboard do
  use AppAnimal
  use AppAnimal.GenServer

  defstruct [:environment, :network, started_circular_clusters: %{}, pulse_rate: 100]

  runs_in_sender do 
    def start_link(%__MODULE__{} = state) do
      GenServer.start_link(__MODULE__, state)
    end
    
    def send_pulse(switchboard_pid, keys) do
      GenServer.cast(switchboard_pid, {:receive_pulse, keys})
    end
    
    def send_pulse_downstream(switchboard_pid, from: source_name, carrying: pulse_data) do
      GenServer.cast(switchboard_pid,
                     {:distribute_downstream, from: source_name, carrying: pulse_data})
    end
    
    # An entry point, called to initiate or reinitiate a network.
    def external_pulse(switchboard_pid, to: destination_name, carrying: pulse_data) do
      GenServer.cast(switchboard_pid,
                     {:distribute_pulse, carrying: pulse_data, to: [destination_name]})
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

      me
      |> Map2.map_within(:network, add_individualized_pulses)
      |> ok()
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me) do
      new_me = ensure_circular_clusters_are_ready(destination_names, me)

      for destination_name <- destination_names do
        destination_pid = new_me.started_circular_clusters[destination_name]
        GenServer.cast(destination_pid, [handle_pulse: pulse_data])
      end
      noreply(new_me)
    end

    def handle_cast({:distribute_downstream, from: source_name, carrying: pulse_data}, me) do
      destination_names = me.network[source_name].downstream
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me)
    end

    def handle_info(:weaken_all_active, me) do
      for {_name, pid} <- me.started_circular_clusters do
        GenServer.cast(pid, [weaken: 1])
      end
      schedule_weakening(me.pulse_rate)
      noreply(me)
    end

    @impl GenServer
    def handle_info({:DOWN, _, :process, pid, _reason}, me) do
      me
      |> Map2.reject_value_within(:started_circular_clusters, pid)
      |> noreply()
    end
    
    private do
      def mkfn__individualized_pulse_downstream(source_name) do
        my_pid = self()
        fn carrying: pulse_data ->
          payload = {:distribute_downstream, from: source_name, carrying: pulse_data}
          GenServer.cast(my_pid, payload)
        end
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

      def schedule_weakening(pulse_delay) do
        Process.send_after(self(), :weaken_all_active, pulse_delay)
      end
    end
  end
end
