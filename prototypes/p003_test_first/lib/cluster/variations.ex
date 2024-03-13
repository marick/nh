alias AppAnimal.Cluster.Variations


defmodule Variations do
  use AppAnimal
  alias AppAnimal.Neural.{CircularCluster, Affordances}

  @type process_map :: %{atom => pid}


  
  defprotocol Topology do
    @spec ensure_ready(Cluster.Base.t, Variations.process_map) :: Variations.process_map
    def ensure_ready(cluster, started_processes)

    @spec generic_pulse(Cluster.Base.t, pid, any) :: no_return
    def generic_pulse(cluster, pid, pulse_data)
  end

  defmodule Topology.Circular do
    defstruct [starting_pulses: 20]

    def new(opts \\ []), do: struct(__MODULE__, opts)
  end

  defmodule Topology.Linear do
    defstruct [:dummy]

    def new(opts \\ []), do: struct(__MODULE__, opts)
  end

  # ===

  defprotocol Propagation do
    @spec put_pid(Propagation.t, {pid, pid}) :: Propagation.t
    def put_pid(propagation, pid)
    
    @spec send_pulse(Propagation.t, any) :: no_return
    def send_pulse(propagation, pulse_data)
  end

  defmodule Propagation.Internal do
    defstruct [:switchboard_pid, :from_name]

    def new(from_name) do
      %__MODULE__{from_name: from_name}
    end

    defimpl Propagation, for: __MODULE__ do
      def put_pid(struct, {switchboard_pid, _affordances_pid}) do
        %{struct | switchboard_pid: switchboard_pid}
      end
      
      def send_pulse(struct, pulse_data) do
        payload = {:distribute_downstream, from: struct.from_name, carrying: pulse_data}
        GenServer.cast(struct.switchboard_pid, payload)
      end
    end
  end
  
  defmodule Propagation.External do
    defstruct [:module, :fun, :pid]

    def new(module, fun) do
      %__MODULE__{module: module, fun: fun}
    end

    defimpl Propagation, for: __MODULE__ do
      def put_pid(struct, {_switchboard_pid, affordances_pid}) do
        %{struct | affordances_pid: affordances_pid}
      end
      
      def send_pulse(struct, pulse_data) do
        apply(struct.module, struct.fun, [struct.pid, pulse_data])
      end
    end
  end


  defmodule Propagation.Test do
    defstruct [:pid, :name]

    def new(name, test_pid) do
      %__MODULE__{pid: test_pid, name: name}
    end

    defimpl Propagation, for: __MODULE__ do
      def put_pid(struct, _predefined) do
        struct
      end
      
      def send_pulse(struct, pulse_data) do
        send(struct.pid, [pulse_data, from: struct.name])
      end
    end
  end
  
  

  # defmodule Variations.ReceivesAsCircular do
  #   defstruct [:pulser]
    
  #   def ensure_ready(cluster, started_processes_by_name) do
  #     case Map.has_key?(started_processes_by_name, cluster.name) do
  #       true ->
  #         started_processes_by_name
  #       false ->
  #         {:ok, pid} = GenServer.start(CircularCluster, cluster)
  #         Process.monitor(pid)
  #         Map.put(started_processes_by_name, cluster.name, pid)
  #     end
  #   end

  #   def generic_pulse(cluster, _destination_pid, pulse_data) do
  #     Task.start(fn ->
  #       cluster.handlers.handle_pulse.(pulse_data, cluster)
  #     end)
  #   end    
  # end

  # defprotocol AppAnimal.Cluster.SendsWhere do
  # end
  

  # defmodule Variations.ReceivesAsX do
  #   defimpl Variations.ReceivesHow, for: __MODULE__  do
  #     def dummy(arg), do: IO.inspect arg
  #   end
  # end
  
  def ensure_ready(%{label: :circular_cluster} = cluster, started_processes_by_name) do
    case Map.has_key?(started_processes_by_name, cluster.name) do
      true ->
        started_processes_by_name
      false ->
        {:ok, pid} = GenServer.start(CircularCluster, cluster)
        Process.monitor(pid)
        Map.put(started_processes_by_name, cluster.name, pid)
    end
  ;end

  def ensure_ready(_cluster, started_processes_by_name) do
    started_processes_by_name
  end

  ##

  def send_to_affordances_pid(cluster, affordances_pid) do 
    sender = fn carrying: {action_name, _action_data} ->
      Affordances.note_action(affordances_pid, action_name)
    end
    %{cluster | send_pulse_downstream: sender,
#                propagate: Propagation.External.new(Affordances, :note_action, affordances_pid)
    }
  end

  def send_to_internal_pid(cluster, switchboard_pid) do
    sender = fn carrying: pulse_data ->
      payload = {:distribute_downstream, from: cluster.name, carrying: pulse_data}
      GenServer.cast(switchboard_pid, payload)
    end
    %{cluster | send_pulse_downstream: sender,
#                propagate: Propagation.Internal.new(switchboard_pid, cluster.name)
    }
  end

  def install_pulse_sender(%{label: :action_edge} = cluster, {_switchboard_pid, affordances_pid}) do
    send_to_affordances_pid(cluster, affordances_pid)
  end

  def install_pulse_sender(cluster, {switchboard_pid, _affordances_pid}) do
    send_to_internal_pid(cluster, switchboard_pid)
  end

  ####

  def generic_pulse(%{label: :circular_cluster}, destination_pid, pulse_data) do
    GenServer.cast(destination_pid, [handle_pulse: pulse_data])
  end

  def generic_pulse(cluster, _destination_pid, pulse_data) do
    Task.start(fn ->
      cluster.handlers.handle_pulse.(pulse_data, cluster)
    end)
  end    
end
