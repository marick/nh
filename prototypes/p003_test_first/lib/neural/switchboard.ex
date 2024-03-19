defmodule AppAnimal.Neural.Switchboard do
  use AppAnimal
  use AppAnimal.GenServer
  use TypedStruct
  alias Neural.ActivityLogger
  alias AppAnimal.Neural.Network

  @type process_map :: %{atom => pid}

  typedstruct do
    plugin TypedStructLens, prefix: :l_

    field :network, Network.t
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

      mutable
      |> deeply_map(l_network(), & Network.individualize_pulses(&1, switchboard_pid, affordances_pid))
      |> continue(returning: :ok)
    end

    @impl GenServer
    def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable) do
      mutable
      |> deeply_map(l_network(), & Network.deliver_pulse(&1, destination_names, pulse_data))
      |> continue
    end

    def handle_cast({:distribute_downstream, from: source_name, carrying: pulse_data}, mutable) do
      source = mutable.network.clusters[source_name]
      destination_names = source.downstream
      ActivityLogger.log_pulse_sent(mutable.logger_pid, source.label, source.name, pulse_data)
      handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, mutable)
    end

    @impl GenServer
    def handle_info(:weaken_all_active, mutable) do
      Network.weaken_all_active(mutable.network)
      schedule_weakening(mutable.pulse_rate)
      continue(mutable)
    end

    def handle_info({:DOWN, _, :process, pid, :normal}, mutable) do
      mutable
      |> deeply_map(l_network(), & Network.drop_active_pid(&1, pid))
      |> continue
    end
    
    private do
      def schedule_weakening(pulse_delay) do
        Process.send_after(self(), :weaken_all_active, pulse_delay)
      end
    end
  end
end
