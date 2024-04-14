alias AppAnimal.Extras

defmodule Extras.KernelTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Extras.Kernel, as: UT
  import Lens.Macros

  defstruct [:clusters]

  deflens l_by_name(name), do: Lens.key!(:clusters) |> Lens.key!(name)
  deflens l_count, do: Lens.key!(:clusters) |> Lens.map_values() |> Lens.key!(:count)
  
  describe "lens utilities" do
    test "all" do
      data = %__MODULE__{clusters: %{fred: %{count: 0},
                                     betty: %{count: 1},
                                     bambam: %{count: 2}}
      }


      result = UT.deeply_put(data, :l_count, "replace")
      
      assert result == %__MODULE__{clusters: %{fred: %{count: "replace"},
                                               betty: %{count: "replace"},
                                               bambam: %{count: "replace"}}}


      result = UT.deeply_get_only(data, l_by_name(:betty))
      assert result == %{count: 1}

      result = UT.deeply_get_all(data, :l_count)
      assert result == [0, 1, 2]


      UT.deeply_map(data, :l_count, & &1*10)
      |> UT.deeply_get_all(:l_count)
      |> assert_equals([00, 10, 20])
    end
  end
end

