defmodule ActivityLogAssertionsTest do
  use ExUnit.Case, async: true
  import FlowAssertions.AssertionA
  alias AppAnimal.ActivityLogAssertions, as: UT
  alias AppAnimal.System.ActivityLogger
  alias AppAnimal.Cluster
  alias ActivityLogger.{PulseSent, ActionReceived}
  import AppAnimal.ActivityLogAssertions, only: [action_taken: 1]

  # I'm not sure where I want to go with this, so I won't update these tests for now.


  def pulse(data, cluster_name, cluster_label) do
    id = Cluster.Identification.new(cluster_name, cluster_label)
    PulseSent.new(id, data)
  end

  describe "element comparison" do
    test "success cases" do
      actual = pulse("data", :a_cluster, :a_label)
      UT.assert_log_entry(actual, a_cluster: "data")
      UT.assert_log_entry(actual, :a_cluster)
    end

    # I doubt it's worthwhile to be more specific about error messages.
    test "failures" do
      actual = pulse("data", :a_cluster, :a_label)

      assertion_fails(
        "Assertion with == failed",
        fn ->
          UT.assert_log_entry(actual, pulse("data", :a_cluster, :a_la))
        end)
    end

    test "action entries match on name" do
      example = ActionReceived.new(:name)
      UT.assert_log_entry(example, action_taken(:name))

      assertion_fails(
        "Field `:name` has the wrong value",
        [left: :name, right: :not_cluster],
        fn ->
          UT.assert_log_entry(example, action_taken(:not_cluster))
        end)
    end



  # describe "assert_log_entries" do
  #   setup do
  #     [actual: [PulseSent.new(:a_label, :a_cluster, "a_data"),
  #               PulseSent.new(:b_label, :b_cluster, "b_data")]]
  #   end

  #   test "compares element by element", %{actual: actual} do
  #     UT.assert_log_entries(actual, actual)
  #     UT.assert_log_entries(actual, [:a_cluster, :b_cluster])
  #     UT.assert_log_entries(actual, [[a_cluster: "a_data"], [b_cluster: "b_data"]])
  #     # This is good enough to imply that `assert_log_entry` is used.
  #   end

  #   test "differing lengths", %{actual: actual} do
  #     assertion_fails(
  #       "The left-hand side has 1 extra value(s).",
  #       fn ->
  #         UT.assert_log_entries(actual, [:a_cluster])
  #       end)

  #     assertion_fails(
  #       "The right-hand side has 1 extra value(s).",
  #       fn ->
  #         UT.assert_log_entries(actual, [:length, :comparison, :first])
  #       end)
  #   end
  # end

  # describe "assert_causal_chain" do
  #   setup do
  #     [actual: [PulseSent.new(:a_label, :a_cluster, "a_data"),
  #               PulseSent.new(:b_label, :b_cluster, "b_data"),
  #               PulseSent.new(:c_label, :c_cluster, "c_data")]]
  #   end

  #   @tag :skip
  #   test "elements can be skipped", %{actual: actual} do
  #     UT.assert_causal_chain(actual, [:a_cluster, :b_cluster])
  #     UT.assert_causal_chain(actual, [:a_cluster, [c_cluster: "c_data"]])
  #   end

  #   test "a name not found will produce an error", %{actual: actual} do
  #     assertion_fails(
  #       "There is no entry matching `:missing`.",
  #       [right: :missing],
  #       fn ->
  #         UT.assert_causal_chain(actual, [:a_cluster, :missing])
  #       end)
  #   end

  #   @tag :skip
  #   test "a pulse_data not found will produce an error", %{actual: actual} do
  #     assertion_fails(
  #       "There is no entry matching `:c_cluster`.",
  #       [right: [c_cluster: "not c_data"]],
  #       fn ->
  #         UT.assert_causal_chain(actual, [:a_cluster, [c_cluster: "not c_data"]])
  #       end)
  #   end

  end
end
