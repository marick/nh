defmodule AppAnimal.Neural.Switchboard do
  use GenServer
  require Logger
  use Private

  defstruct [:environment, :network, started_circular_clusters: %{}]

  def start_link(%__MODULE__{} = state) do
    GenServer.start_link(__MODULE__, state)
  end

  def send_pulse(switchboard, keys) do
    GenServer.cast(switchboard, {:receive_pulse, keys})
  end

  def send_pulse_downstream(from: source_name, carrying: pulse_data, via: switchboard_pid) do
    GenServer.cast(switchboard_pid,
                   {:distribute_downstream, from: source_name, carrying: pulse_data})
  end

  # An entry point, called to initiate or reinitiate a network.
  def initial_pulse(to: destination_name, carrying: pulse_data, via: switchboard_pid) do
    GenServer.cast(switchboard_pid,
                   {:distribute_pulse, carrying: pulse_data, to: [destination_name]})
  end

  def mkfn__individualized_pulse_downstream(source_name) do
    my_pid = self()
    fn carrying: pulse_data ->
      payload = {:distribute_downstream, from: source_name, carrying: pulse_data}
      GenServer.cast(my_pid, payload)
    end
  end

  @impl GenServer
  def init(me) do
    augmented_network =
      for {name, structure} <- me.network, into: %{} do
        sender = mkfn__individualized_pulse_downstream(structure.name)
        {name, %{structure | send_pulse_downstream: sender}}
      end
    Process.send_after(self(), :tick, 100)
    {:ok, %{me | network: augmented_network}}
  end

  @impl GenServer
  def handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me) do
    new_me = ensure_circular_clusters_are_ready(destination_names, me)

    for destination_name <- destination_names do
      destination_pid = new_me.started_circular_clusters[destination_name]
      GenServer.cast(destination_pid, [handle_pulse: pulse_data])
    end
    {:noreply, new_me}
  end

  def handle_cast({:distribute_downstream, from: source_name, carrying: pulse_data}, me) do
    destination_names = me.network[source_name].downstream

    handle_cast({:distribute_pulse, carrying: pulse_data, to: destination_names}, me)
  end

  @impl GenServer
  def handle_info(:tick, me) do
    for {_name, pid} <- me.started_circular_clusters do
      GenServer.cast(pid, [weaken: 1])
    end
    Process.send_after(self(), :tick, 100)
    {:noreply, me}
  end

  def handle_info({:DOWN, _, :process, pid, _reason}, me) do
    {:noreply, reject_value_within(me, :started_circular_clusters, pid)}
  end

  # TODO: pull this into a helper module
  def reject_value_within(outer_map, key, rejected_value) do
    inner_map = Map.get(outer_map, key)
    transformed = 
      for {k, v} <- inner_map,
          v != rejected_value,
          into: %{},
          do: {k, v}
    Map.put(outer_map, key, transformed)
  end
    
  private do
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
  end
end
