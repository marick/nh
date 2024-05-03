alias AppAnimal.{ClusterBuilders,Scenario}

defmodule ClusterBuilders.FocusShiftTest do
  use Scenario.Case, async: true
  alias ClusterBuilders, as: UT
  alias System.{Pulse,Delay}

  def focus_shift do
    UT.focus_shift(:my_focus,
                   movement_time: Duration.seconds(0.05),
                   action: :look_for_paragraph_shape)
  end


  test "static fields" do
    assert_fields(focus_shift(), router: :must_be_supplied_later,
                                 id: Identification.new(:my_focus, :focus_shift),
                                 name: :my_focus)
  end

  test "suppresses downstream circular clusters AND sends timer delay" do
    # You cannot send a timer pulse directly to the test process: a
    # restriction of `Process.send_after`.
    p_timer = start_link_supervised!(Network.Timer)

    router = System.Router.new(%{Pulse => self(), Delay => p_timer})

    s_cluster = focus_shift() |> Map.put(:router, router)

    p_cluster = start_link_supervised!({Cluster.CircularProcess, s_cluster})
    GenServer.cast(p_cluster, [handle_pulse: Pulse.new("paragraph id")])

    assert_receive(_)
    |> assert_distribute_from(from: s_cluster.name, pulse: Pulse.new(:suppress, "no data"))

    Process.sleep(Duration.seconds(0.05))

    assert_receive(_)
    |> assert_distribute_to(to: [s_cluster.name],
                            pulse: Pulse.new(:movement_finished, "paragraph id"))
  end
end
