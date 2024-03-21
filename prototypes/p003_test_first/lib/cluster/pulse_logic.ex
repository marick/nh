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
  defstruct [:p_switchboard, :pid_taker]

  def new(pid_taker) do
    %__MODULE__{pid_taker: pid_taker}
  end
end

defimpl PulseLogic, for: PulseLogic.Internal do
  def put_pid(struct, {p_switchboard, _p_affordances}) do
    %{struct | p_switchboard: p_switchboard}
  end
    
  def send_pulse(struct, pulse_data) do
    struct.pid_taker.(struct.p_switchboard, pulse_data)
  end
end

## 
  
defmodule PulseLogic.External do
  defstruct [:pid_taker, :pid]

  def new(pid_taker) do
    %__MODULE__{pid_taker: pid_taker}
  end

end

defimpl PulseLogic, for: PulseLogic.External do
  def put_pid(struct, {_p_switchboard, p_affordances}) do
    %{struct | pid: p_affordances}
  end
    
  def send_pulse(struct, pulse_data) do
    struct.pid_taker.(struct.pid, pulse_data)
  end
end

## 

defmodule PulseLogic.Test do
  defstruct [:pid, :pid_taker]

  def new(pid_taker, test_pid) do
    %__MODULE__{pid: test_pid, pid_taker: pid_taker}
  end
end

defimpl PulseLogic, for: PulseLogic.Test do
  def put_pid(struct, _predefined) do
    struct
  end
      
  def send_pulse(struct, pulse_data) do
    struct.pid_taker.(struct.pid, pulse_data)
  end
end
  

