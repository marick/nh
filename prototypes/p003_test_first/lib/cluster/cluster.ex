alias AppAnimal.{Cluster, System}

defmodule Cluster do
  use AppAnimal

  def start_pulse_on_its_way(s_cluster, %System.Pulse{} = pulse) do
    router = s_cluster.router
    System.Router.cast_via(router, pulse, from: s_cluster.name)
  end

  def start_pulse_on_its_way(s_cluster, %System.Action{} = action) do
    router = s_cluster.router
    System.Router.cast_via(router, action)
  end
end
