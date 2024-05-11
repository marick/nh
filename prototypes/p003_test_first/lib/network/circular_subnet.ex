alias AppAnimal.{Network,Cluster}

defmodule Network.CircularSubnet do
  @moduledoc """
  The portion of a `Network` that changes state as circular clusters
  are started and stop.

  This keeps track of the lifespan of throbbing clusters. It also sends messages
  to them. This hides knowledge of lifespans inside this module.

  This module stores all the circular clusters known in the `Network`, not just the
  ones that are actively throbbing.
  """
  use AppAnimal
  use AppAnimal.StructServer
  use MoveableAliases

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name_to_pid, BiMap.t(atom, pid), default: BiMap.new
    field :name_to_cluster, %{atom => Cluster.Circular.t}
  end

  deflens routers,
          do: name_to_cluster() |> Lens.map_values() |> Cluster.Circular.router()

  runs_in_receiver do
    @impl GenServer
    def init(clusters) do
      indexed =
        for c <- clusters, into: %{}, do: {c.name, c}
      {:ok, %__MODULE__{name_to_cluster: indexed}}
    end

    @impl GenServer
    # Eventually, there may be a more sophisticated way of deciding whether a
    # pulse should start the cluster throbbing. For now, it's only done for `:default`
    # pulses.
    def handle_cast({:distribute_pulse, opts}, s_subnet) do
      [pulse, names] = Opts.required!(opts, [:carrying, :to])
      if pulse.type == :default,
         do:   distribute_then_continue(pulse, names, ensure_started(s_subnet, names)),
         else: distribute_then_continue(pulse, names,                s_subnet        )
    end

    def handle_cast(:time_to_throb, s_subnet) do
      throb(BiMap.values(s_subnet.name_to_pid))
      continue(s_subnet)
    end

    @impl GenServer
    def handle_info({:DOWN, _, :process, pid, _}, s_subnet) do
      s_subnet.name_to_pid
      |> BiMap.delete_value(pid)
      |> then(& Map.put(s_subnet, :name_to_pid, &1))
      |> continue
    end


    # This is used for testing as a way to get internal values of clusters.
    @impl GenServer
    def handle_call([forward: getter_name, to: name], _from, s_subnet) do
      result =
        BiMap.get(s_subnet.name_to_pid, name)
        |> GenServer.call(getter_name)
      continue(s_subnet, returning: result)
    end

    def handle_call(:clusters, _from, s_subnet) do
      values = Map.values(s_subnet.name_to_cluster)
      continue(s_subnet, returning: values)
    end

    def handle_call(:throbbing_names, _from, s_subnet) do
      keys = BiMap.keys(s_subnet.name_to_pid)
      continue(s_subnet, returning: keys)
    end

    def handle_call(:throbbing_pids, _from, s_subnet) do
      values = BiMap.values(s_subnet.name_to_pid)
      continue(s_subnet, returning: values)
    end

    def handle_call({:router_for, name}, _from, s_subnet) do
      router = s_subnet.name_to_cluster[name] |> A.get_only(:router)
      continue(s_subnet, returning: router)
    end

    def handle_call({:add_cluster, %Cluster.Circular{} = cluster}, _from, s_subnet) do
      precondition Map.has_key?(s_subnet, :name_to_cluster)

      s_subnet
      |> A.put(name_to_cluster() |> Lens.key(cluster.name), cluster)
      |> continue(returning: :ok)
    end

    def handle_call({:add_router_to_all, router}, _from, s_subnet) do
      s_subnet
      |> A.put(:routers, router)
      |> continue(returning: :ok)
    end

    unexpected_call()
    unexpected_cast()

    private do
      def ensure_started(s_subnet, names) do
        reducer = fn name, bimap ->
          if BiMap.has_key?(bimap, name) do
            bimap
          else
            cluster = Map.get(s_subnet.name_to_cluster, name)
            {:ok, pid} = GenServer.start(Cluster.CircularProcess, cluster)
            Process.monitor(pid)
            BiMap.put(bimap, name, pid)
          end
        end

        new_bimap = Enum.reduce(names, s_subnet.name_to_pid, reducer)
        %{s_subnet | name_to_pid: new_bimap}
      end

      def distribute_then_continue(pulse, names, s_subnet) do
        send_to_throbbers(s_subnet.name_to_pid, names, pulse)
        continue(s_subnet)
      end

      def send_to_throbbers(name_to_pid, names, pulse) do
        throbbers =
          names
          |> Enum.map(& BiMap.get(name_to_pid, &1))
          |> Enum.reject(&is_nil/1)

        Enum.each(throbbers, & GenServer.cast(&1, [handle_pulse: pulse]))
      end

      def throb(pids) do
        for pid <- pids, do: GenServer.cast(pid, [throb: 1])
      end
    end
  end
end
