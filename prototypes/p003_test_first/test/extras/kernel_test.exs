alias AppAnimal.Extras

defmodule Extras.KernelTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Extras.Kernel, as: UT

  defstruct [:clusters]

  def _by_name(name), do: Lens.key!(:clusters) |> Lens.key!(name)
  def _count, do: Lens.key!(:clusters) |> Lens.map_values() |> Lens.key!(:count)
  
  describe "lens utilities" do
    test "all" do
      data = %__MODULE__{clusters: %{fred: %{count: 0},
                                     betty: %{count: 1},
                                     bambam: %{count: 2}}
      }


      result = UT.deeply_put(data, :_count, "replace")
      
      assert result == %__MODULE__{clusters: %{fred: %{count: "replace"},
                                               betty: %{count: "replace"},
                                               bambam: %{count: "replace"}}}


      result = UT.deeply_get_only(data, _by_name(:betty))
      assert result == %{count: 1}

      result = UT.deeply_get_all(data, :_count)
      assert result == [0, 1, 2]


      UT.deeply_map(data, :_count, & &1*10)
      |> UT.deeply_get_all(:_count)
      |> assert_equals([00, 10, 20])
    end
  end
end

