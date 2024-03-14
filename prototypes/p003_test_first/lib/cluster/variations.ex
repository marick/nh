alias AppAnimal.Cluster.Variations


defmodule Variations do
  use AppAnimal

  @type process_map :: %{atom => pid}

  defprotocol Propagation do
    @spec put_pid(Propagation.t, {pid, pid}) :: Propagation.t
    def put_pid(propagation, pid)
    
    @spec send_pulse(Propagation.t, any) :: no_return
    def send_pulse(propagation, pulse_data)
  end

  defmodule Propagation.Internal do
    defstruct [:switchboard_pid, :from_name]

    def new(from_name: from_name) do
      %__MODULE__{from_name: from_name}
    end
  end

  defimpl Propagation, for: Propagation.Internal do
    def put_pid(struct, {switchboard_pid, _affordances_pid}) do
      %{struct | switchboard_pid: switchboard_pid}
    end
    
    def send_pulse(struct, pulse_data) do
      payload = {:distribute_downstream, from: struct.from_name, carrying: pulse_data}
      GenServer.cast(struct.switchboard_pid, payload)
    end
  end
  
  defmodule Propagation.External do
    defstruct [:module, :fun, :pid]

    def new(module, fun) do
      %__MODULE__{module: module, fun: fun}
    end

  end

  defimpl Propagation, for: Propagation.External do
    def put_pid(struct, {_switchboard_pid, affordances_pid}) do
      %{struct | pid: affordances_pid}
    end
    
    def send_pulse(struct, pulse_data) do
      apply(struct.module, struct.fun, [struct.pid, pulse_data])
    end
  end

  defmodule Propagation.Test do
    defstruct [:pid, :name]

    def new(name, test_pid) do
      %__MODULE__{pid: test_pid, name: name}
    end
  end

  defimpl Propagation, for: Propagation.Test do
      def put_pid(struct, _predefined) do
        struct
      end
      
      def send_pulse(struct, pulse_data) do
        send(struct.pid, [pulse_data, from: struct.name])
      end
    end
  


  # ===


  ##

  def send_to_affordances_pid(cluster, affordances_pid) do 
    cluster
    |> Map.update!(:propagate, & Propagation.put_pid(&1, {:foo, affordances_pid}))
  end

  def send_to_internal_pid(cluster, switchboard_pid) do
    sender = fn carrying: pulse_data ->
      payload = {:distribute_downstream, from: cluster.name, carrying: pulse_data}
      GenServer.cast(switchboard_pid, payload)
    end
    cluster
    |> Map.put(:send_pulse_downstream, sender)
    |> Map.update!(:propagate, & Propagation.put_pid(&1, {switchboard_pid, :foo}))
  end

  def install_pulse_sender(%{label: :action_edge} = cluster, {_switchboard_pid, affordances_pid}) do
    send_to_affordances_pid(cluster, affordances_pid)
  end

  def install_pulse_sender(cluster, {switchboard_pid, _affordances_pid}) do
    send_to_internal_pid(cluster, switchboard_pid)
  end
end
