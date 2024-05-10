alias AppAnimal.ClusterBuilders

defmodule ClusterBuilders.CircularTest do
  use AppAnimal.Case, async: true
  alias Cluster.{Circular,Throb}

  describe "variants of circular creation" do

    test "only a name is specified" do
      C.circular(:name)
      |> assert_fields(name: :name,
                       id: Identification.new(:name, :circular),
                       throb: Throb.default,
                       calc: &Function.identity/1,
                       previously: %{})
    end

    test "name and options" do
      C.circular(:name, previously: 3)
      |> assert_fields(name: :name,
                       id: Identification.new(:name, :circular),
                       throb: Throb.default,
                       calc: &Function.identity/1,

                       previously: 3)
    end

    test "name and calc" do
      f = & &1+1
      C.circular(:rounder, f)
      |> assert_fields(name: :rounder,
                       id: Identification.new(:rounder, :circular),
                       throb: Throb.default,
                       calc: f,
                       previously: %{})
    end


    test "name, calc, and options" do
      alias AppAnimal.Duration
      f = & &1+1
      throb = Throb.counting_down_from(Duration.quanta(3))
      C.circular(:rounder, f, throb: throb, previously: 5)
      |> assert_fields(name: :rounder,
                       id: Identification.new(:rounder, :circular),
                       throb: throb,
                       f_while_stopping: &Circular.stop_silently/1,
                       calc: f,
                       previously: 5)
    end

    test "initial_value is a valid opts (a synonym for `previously`)" do
      initial_value = %{pids: [], count: 5}
      C.circular(:first, initial_value: initial_value)
      |> assert_fields(name: :first,
                       id: Identification.new(:first, :circular),
                       calc: &Function.identity/1,
                       previously: initial_value)
    end

    test "while_stopping option" do
      C.circular(:first, while_stopping: &Circular.pulse_current_value/1)
      |> assert_field(f_while_stopping: &Circular.pulse_current_value/1)
    end
  end
end
