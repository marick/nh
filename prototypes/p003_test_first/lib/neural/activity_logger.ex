defmodule AppAnimal.Neural.ActivityLogger do
  use AppAnimal
  use AppAnimal.GenServer
  require CircularBuffer


  defstruct [:buffer, also_to_terminal: false]
  
  defmodule PulseSent do
    @enforce_keys [:cluster_type, :name, :pulse_data]
    defstruct [:cluster_type, :name, :pulse_data]

    def new(cluster_type, name, pulse_data) do
      %__MODULE__{cluster_type: cluster_type, name: name, pulse_data: pulse_data}
    end
  end

  # An earlier version of this module used
  #    Logger.put_process_level(self(), :debug)
  # It turns out that isn't implemented.
  # https://elixirforum.com/t/struggling-with-logger-put-process-level/58702
  #
  # So instead of relying on each ActivityLogger being an independent process,
  # I have to mess around with state. Bah. As a result of its history, this is
  # probably the Wrong Thing.
  

  runs_in_sender do 
    def start_link(buffer_size \\ 100) do
      GenServer.start_link(__MODULE__, buffer_size)
    end
    
    def spill_log_to_terminal(pid) do
      GenServer.call(pid, [also_to_terminal: true])
    end

    def silence_terminal_log(pid) do
      GenServer.cast(pid, [also_to_terminal: false])
    end

    def log_pulse_sent(pid, type, name, pulse_data) do
      entry = %PulseSent{cluster_type: type, name: name, pulse_data: pulse_data}
      GenServer.cast(pid, [log: entry])
    end

    def get_log(pid) do
      GenServer.call(pid, :get_log)
    end
  end

  runs_in_receiver do
    def init(buffer_size) do
      %__MODULE__{buffer: CircularBuffer.new(buffer_size)}
      |> ok()
    end

    def handle_call([also_to_terminal: value], _from, me) do
      %{me | also_to_terminal: value}
      |> continue(returning: :ok)
    end

    def handle_call(:get_log, _from, me) do
      continue(me, returning: CircularBuffer.to_list(me.buffer))
    end

    def handle_cast([log: entry], me) do
      if me.also_to_terminal,
         do: Logger.info(inspect(entry.pulse_data), pulse_entry: entry)
      
      update_in(me.buffer, &(CircularBuffer.insert(&1, entry)))
      |> continue
    end
  end
end
