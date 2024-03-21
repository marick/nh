alias AppAnimal.Cluster
alias Cluster.PulseLogic


defprotocol PulseLogic do
  @spec put_pid(PulseLogic.t, {pid, pid}) :: PulseLogic.t
  def put_pid(propagation, pid)
end

## 

defmodule PulseLogic.Internal do
  defstruct [:pid, :pid_taker]

  def new(pid_taker) do
    %__MODULE__{pid_taker: pid_taker}
  end
end

defimpl PulseLogic, for: PulseLogic.Internal do
  def put_pid(struct, {p_switchboard, _p_affordances}) do
    %{struct | pid: p_switchboard}
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
end
  

