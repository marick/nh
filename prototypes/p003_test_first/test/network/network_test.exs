alias AppAnimal.Network

defmodule Network.NetworkTest do
  use ClusterCase, async: true
  alias Network, as: UT

  UT
  # defp named(names) when is_list(names),
  #      do: Enum.map(names, &named/1)
  # defp named(name),
  #      do: circular(name)

end
