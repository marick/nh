alias AppAnimal.{Building,Cluster}

defmodule Building.PartsTest do
  use ExUnit.Case, async: true
  use FlowAssertions
  alias Building.Parts, as: UT

  describe "variants of circular creation" do

    test "only a name is specified" do 
      UT.circular(:name)
      |> assert_fields(name: :name,
                       id: Cluster.Identification.new(:name, :circular),
                       throb: Cluster.Throb.default,
                       calc: &Function.identity/1,
                       previously: %{})
    end
        
      
    # UT.circular(:name, & &1+1)
    # UT.circular(:name, x: 1, y: 2)
    # UT.circular(:name, & &1+1, x: 1, y: 2)
  end
  

end

