alias AppAnimal.{Cluster,Scenario}

defmodule Cluster.DelayTest do
  use Scenario.Case, async: true

  test "static parts" do
    C.delay(:first, 2)
    |> assert_fields(router: :must_be_supplied_later,
                     id: Identification.new(:first, :delay),
                     name: :first)
    |> Map.get(:throb)
    |> assert_fields(max_age: 2, current_age: 0)
  end


  describe "delay" do
    setup do
      animal =
        configuration throb_interval: Duration.foreverish do
          trace [C.delay(:first, 2), forward_to_test()]
        end
      [animal: animal]
    end

    test "delay for some throbs", %{animal: animal} do
      Animal.send_test_pulse(animal, to: :first, carrying: "data")
      refute_receive("data")

      # It will take two throbs to get data
      Animal.throb_all_active(animal)
      refute_receive(_)

      Animal.throb_all_active(animal)
      assert_test_receives("data")
    end

    test "a pulse starts the delay over again", %{animal: animal} do
      Animal.send_test_pulse(animal, to: :first, carrying: "data")
      refute_receive("data")

      Animal.throb_all_active(animal)
      refute_receive(_)
      assert Animal.peek_at(animal, :current_age, of: :first) == 1

      # pulse cancels out throbbing
      Animal.send_test_pulse(animal, to: :first, carrying: "replacement data")
      refute_receive(_)
      assert Animal.peek_at(animal, :current_age, of: :first) == 0

      Animal.throb_all_active(animal)
      refute_receive(_)

      # Note that the replacement data is sent
      Animal.throb_all_active(animal)
      assert_test_receives("replacement data")
    end
  end
end
