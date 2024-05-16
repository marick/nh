alias AppAnimal.{ClusterBuilders,Scenario}

defmodule ClusterBuilders.FocusShiftTest do
  use Scenario.Case, async: true
  use MoveableAliases

  def paragraph_focus(router_map \\ %{}) do
    router = Moveable.Router.new(router_map)
    C.focus_shift(:my_focus,
                   movement_time: Duration.seconds(0.05),
                   action_type: :perceive_paragraph_shape)
    |> Map.put(:router, router)
  end

  test "static fields" do
    paragraph_focus()
    |> assert_fields(id: Identification.new(:my_focus, :focus_shift),
                     name: :my_focus,
                     router: Moveable.Router.new(%{}))
  end

  @tag :test_uses_sleep
  test "suppresses downstream circular clusters AND sends timer delay" do
    # You cannot send a timer pulse directly to the test process: a
    # restriction of `Process.send_after`.
    p_timer = start_link_supervised!(Network.Timer)

    s_cluster = paragraph_focus(%{Pulse => self(), Delay => p_timer})
    p_cluster = start_link_supervised!({Cluster.CircularProcess, s_cluster})
    GenServer.cast(p_cluster, [handle_pulse: Pulse.new("paragraph id")])

    assert_receive(_)
    |> assert_distribute_from(from: s_cluster.name, pulse: Pulse.suppress)

    Process.sleep(Duration.seconds(0.05))

    assert_receive(_)
    |> assert_distribute_to(to: [s_cluster.name],
                            pulse: Pulse.new(:movement_finished, "paragraph id"))
  end

  test "sends action when timer finishes" do
    s_cluster = paragraph_focus(%{Action => self()})
    p_cluster = start_link_supervised!({Cluster.CircularProcess, s_cluster})
    GenServer.cast(p_cluster, [handle_pulse: Pulse.new(:movement_finished, "paragraph id")])

    assert_receive(_)
    |> assert_action_taken(Action.new(:perceive_paragraph_shape, "paragraph id"))
  end

  test "ignores throbbing" do
    s_cluster = paragraph_focus(%{Action => self()})
    p_cluster = start_link_supervised!({Cluster.CircularProcess, s_cluster})

    Enum.each(0..10000, fn _ ->
      GenServer.cast(p_cluster, [throb: 100])
    end)

    GenServer.cast(p_cluster, [handle_pulse: Pulse.new(:movement_finished, "paragraph id")])

    assert_receive(_)
    |> assert_action_taken(Action.new(:perceive_paragraph_shape, "paragraph id"))
  end
end
