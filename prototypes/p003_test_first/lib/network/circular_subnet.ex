alias AppAnimal.{Network,Cluster}

defmodule Network.CircularSubnet do
  @moduledoc """
  The portion of a `Network` that changes state as circular clusters
  are started and stop.

  This keeps track of the lifespan of throbbing clusters. It also sends messages
  to them. This hides knowledge of lifespans inside this module.

  This module stores all the circular clusters known in the
  `AppAnimal.Network`, not just the ones that are actively throbbing.

  A circular cluster has to be `start_linked` (a synchronous
  operation), then a pulse can be `cast` at it.
  """
  use AppAnimal
  use AppAnimal.StructServer
  use MoveableAliases

  typedstruct enforce: true do
    plugin TypedStructLens

    field :name_to_pid, BiMap.t(atom, pid), default: BiMap.new
    field :name_to_cluster, %{atom => Cluster.Circular.t}
  end

  section "lenses" do
    deflens clusters(),           do: name_to_cluster() |> Lens.map_values()
    deflens cluster_for(name),    do: name_to_cluster() |> Lens.key(name)
    deflens router_for(name),  do: cluster_for(name) |> Cluster.Circular.router()

    deflens routers,       do: clusters() |> Cluster.Circular.router()

    deflens pids,             do: name_to_pid() |> LensX.bimap_all_values()
    deflens pid_for(name),    do: name_to_pid() |> LensX.bimap_key(name)
    deflens pids_for?(names), do: name_to_pid() |> LensX.bimap_keys?(names)

    deflens throbbing_names, do: name_to_pid() |> LensX.bimap_all_keys
    deflens throbbing_pids,  do: name_to_pid() |> LensX.bimap_all_values
  end


  runs_in_receiver do
    @impl GenServer
    def init(clusters) do
      indexed =
        for c <- clusters, into: %{}, do: {c.name, c}
      {:ok, %__MODULE__{name_to_cluster: indexed}}
    end

    handle_CAST do
      # Eventually, there may be a more sophisticated way of deciding whether a
      # pulse should start the cluster throbbing. For now, it's only done for `:default`
      # pulses.
      def handle_cast({:distribute_pulse, opts}, s_subnet) do
        [pulse, names] = Opts.required!(opts, [:carrying, :to])
        if pulse.type == :default,
           do:   distribute_then_continue(pulse, names, ensure_throbbing(s_subnet, names)),
           else: distribute_then_continue(pulse, names,                  s_subnet        )
      end

      def handle_cast(:time_to_throb, s_subnet) do
        A.each(s_subnet, :pids, & GenServer.cast(&1, [throb: 1]))
        continue(s_subnet)
      end
    end


    handle_INFO do
      def handle_info({:DOWN, _, :process, pid, _}, s_subnet) do
        s_subnet
        |> A.map(:name_to_pid, & BiMap.delete_value(&1, pid))
        |> continue
      end
    end


    handle_CALL do
      defget :one, router_for: 1

      def handle_call({:add_cluster, %Cluster.Circular{} = cluster}, _from, s_subnet) do
        s_subnet
        |> A.put(cluster_for(cluster.name), cluster)
        |> continue(returning: :ok)
      end

      def handle_call({:add_router_to_all, router}, _from, s_subnet) do
        s_subnet
        |> A.put(:routers, router)
        |> continue(returning: :ok)
      end

      section "test helpers" do
        # This is used for testing as a way to get internal values of clusters.
        def handle_call([forward: getter_name, to: name], _from, s_subnet) do
          result =
            A.one!(s_subnet, pid_for(name))
            |> GenServer.call(getter_name)
          continue(s_subnet, returning: result)
        end

        defget :many, clusters: 0,
                      throbbing_names: 0,
                      throbbing_pids: 0
      end
    end

    private do
      def ensure_throbbing(s_subnet, cluster_names) do
        provide_missing_keys = name_to_pid() |> LensX.bimap_missing_keys(cluster_names)

        A.map(s_subnet, provide_missing_keys, fn missing_key ->
          cluster = A.one!(s_subnet, cluster_for(missing_key))
          {:ok, pid} = GenServer.start(Cluster.CircularProcess, cluster)
          Process.monitor(pid)
          pid
        end)
      end

      def distribute_then_continue(pulse, cluster_names, s_subnet) do
        A.each(s_subnet, pids_for?(cluster_names), fn pid ->
          GenServer.cast(pid, [handle_pulse: pulse])
        end)
        continue(s_subnet)
      end
    end
  end
end
