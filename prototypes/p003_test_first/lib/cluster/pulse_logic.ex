alias AppAnimal.Cluster
alias Cluster.PulseLogic


defprotocol PulseLogic do
  @spec put_pid(PulseLogic.t, {pid, pid}) :: PulseLogic.t
  def put_pid(propagation, pid)
    
  @spec send_pulse(PulseLogic.t, any) :: no_return
  def send_pulse(propagation, pulse_data)
end

## 

defmodule PulseLogic.Internal do
  defstruct [:p_switchboard, :from_name]

  def new(from_name: from_name) do
    %__MODULE__{from_name: from_name}
  end
end

defimpl PulseLogic, for: PulseLogic.Internal do
  def put_pid(struct, {p_switchboard, _p_affordances}) do
    %{struct | p_switchboard: p_switchboard}
  end
    
  def send_pulse(struct, pulse_data) do
    payload = {:distribute_pulse, carrying: pulse_data, from: struct.from_name}
    GenServer.cast(struct.p_switchboard, payload)
  end
end

## 
  
defmodule PulseLogic.External do
  defstruct [:module, :fun, :pid]

  def new(module, fun) do
    %__MODULE__{module: module, fun: fun}
  end

end

defimpl PulseLogic, for: PulseLogic.External do
  def put_pid(struct, {_p_switchboard, p_affordances}) do
    %{struct | pid: p_affordances}
  end
    
  def send_pulse(struct, pulse_data) do
    apply(struct.module, struct.fun, [struct.pid, pulse_data])
  end
end

## 

defmodule PulseLogic.Test do
  defstruct [:pid, :name]

  def new(name, test_pid) do
    %__MODULE__{pid: test_pid, name: name}
  end
end

defimpl PulseLogic, for: PulseLogic.Test do
  def put_pid(struct, _predefined) do
    struct
  end
      
  def send_pulse(struct, pulse_data) do
    send(struct.pid, [pulse_data, from: struct.name])
  end
end
  

