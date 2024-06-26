alias AppAnimal.Extras

defmodule Extras.DepthAgnosticTest do
  use AppAnimal.Case, async: true
  alias Extras.DepthAgnostic, as: A   # as is customary
  import Lens.Macros

  typedstruct do
    plugin TypedStructLens

    field :clusters, %{}, default: %{}
  end

  deflens by_name(name), do: clusters() |> Lens.key!(name)
  deflens count, do: clusters() |> Lens.map_values() |> Lens.key!(:count)

  describe "lens utilities" do
    test "all of them" do
      data = %__MODULE__{clusters: %{fred: %{count: 0},
                                     betty: %{count: 1},
                                     bambam: %{count: 2}}
      }


      result = A.put(data, :count, "replace")

      assert result == %__MODULE__{clusters: %{fred: %{count: "replace"},
                                               betty: %{count: "replace"},
                                               bambam: %{count: "replace"}}}


      result = A.one!(data, by_name(:betty))
      assert result == %{count: 1}

      result = A.to_list(data, :count)
      assert result == [0, 1, 2]


      A.map(data, :count, & &1*10)
      |> A.to_list(:count)
      |> assert_equals([00, 10, 20])
    end
  end
end
