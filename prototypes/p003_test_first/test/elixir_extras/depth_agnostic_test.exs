alias AppAnimal.Extras

defmodule Extras.DepthAgnosticTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Extras.DepthAgnostic, as: A   # as is customary
  import Lens.Macros

  use TypedStruct

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


      result = A.get_only(data, by_name(:betty))
      assert result == %{count: 1}

      result = A.get_all(data, :count)
      assert result == [0, 1, 2]


      A.map(data, :count, & &1*10)
      |> A.get_all(:count)
      |> assert_equals([00, 10, 20])
    end
  end
end

