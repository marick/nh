defmodule ClusterCase do
  use AppAnimal
  alias AppAnimal.Neural
  alias Neural.Switchboard
  alias Neural.NetworkBuilder, as: Builder
  import ExUnit.Callbacks, only: [start_link_supervised!: 1]
  
  def forward_pulse_to_test do
    test_pid = self()
    fn pulse_data, mutable, _configuration ->
      send(test_pid, pulse_data)
      mutable
    end
  end

  def switchboard_from(clusters, keys \\ []) when is_list(clusters) do
    network = Builder.start(clusters)
    state = struct(Switchboard,
                   Keyword.merge([environment: "irrelevant", network: network], keys))
    start_link_supervised!({Switchboard, state})
  end

  defmacro __using__(keys) do
    quote do
      use ExUnit.Case, unquote(keys)
      use AppAnimal
      alias AppAnimal.Neural
      alias Neural.Switchboard
      import Neural.ClusterMakers
      import ClusterCase
    end
  end
end
