alias AppAnimal.{ClusterBuilders,Scenario}

defmodule ClusterBuilders.FocusShiftTest do
  use Scenario.Case, async: true
  alias ClusterBuilders, as: UT
  alias System.{Pulse}

  def focus_shift do
    UT.focus_shift(:my_focus,
                   movement_time: Duration.quanta(5),
                   action: :look_for_paragraph_shape)
  end


  test "static fields" do
    assert_fields(focus_shift(), router: :must_be_supplied_later,
                                 id: Identification.new(:my_focus, :focus_shift),
                                 name: :my_focus)
  end


  def distribute_what_pulse(pattern) do
    {:distribute_pulse, carrying: pulse, from: _} = pattern
    pulse
  end

  def pulse_to_switchboard() do
    {:"$gen_cast", cast} = assert_receive(_)
    distribute_what_pulse(cast)
  end

  test "suppresses downstream circular clusters" do
    router = System.Router.new(%{Pulse => self()})
    s_cluster = focus_shift() |> Map.put(:router, router)

    p_cluster = start_link_supervised!({Cluster.CircularProcess, s_cluster})
    GenServer.cast(p_cluster, [handle_pulse: Pulse.new("paragraph id")])

    assert pulse_to_switchboard().type == :suppress

  end
end
