defmodule TraceAssertionsTest do
  use ExUnit.Case, async: true
  import FlowAssertions.AssertionA
#  import FlowAssertions.TabularA
  alias AppAnimal.TraceAssertions, as: UT
  alias AppAnimal.Neural.ActivityLogger
  alias ActivityLogger.{PulseSent, ActionReceived}
  import AppAnimal.TraceAssertions, only: [action: 1]


  describe "element comparison" do
    test "success cases" do
      actual = PulseSent.new(:a_label, :a_name, "data")
      
      UT.assert_log_entry(actual, PulseSent.new(:a_label, :a_name, "data"))
      UT.assert_log_entry(actual, [a_name: "data"])
      UT.assert_log_entry(actual, :a_name)
    end

    test "reporting of field failures is per `assert_fields`" do
      actual = PulseSent.new(:a_label, :a_name, "data")

      assertion_fails(
        "Assertion with == failed",
        fn -> 
          UT.assert_log_entry(actual, PulseSent.new(:a_typ, :a_name, "data"))
        end)

      assertion_fails(
        "Field `:name` has the wrong value",
        [left: :a_name, right: :a_ame],
        fn -> 
          UT.assert_log_entry(actual, [a_ame: "data"])
        end)

      assertion_fails(
        "Field `:pulse_data` has the wrong value",
        [left: "data", right: "dat"],
        fn -> 
          UT.assert_log_entry(actual, [a_name: "dat"])
        end)
    end

    test "action entries match on name" do
      example = ActionReceived.new(:name)
      UT.assert_log_entry(example, action(:name))

      assertion_fails(
        "Field `:name` has the wrong value",
        [left: :name, right: :not_name],
        fn -> 
          UT.assert_log_entry(example, action(:not_name))
        end)
    end

    test "can't compare different types of entries" do
      actual = PulseSent.new(:a_label, :a_name, "data")

      plain_map = %{cluster_label: :a_label, name: :a_name, pulse_data: "data"}
      assertion_fails(
        "The expectation cannot match a PulseSent.",
        [right: plain_map],
        fn ->
          UT.assert_log_entry(actual, plain_map)
        end)

      focus = action(:name)
      assertion_fails(
        "The expectation, for ActionReceived, cannot match a PulseSent.",
        fn ->
          UT.assert_log_entry(actual, focus)
        end)

    end
  end
  
  
  describe "assert_exact_trace" do
    setup do
      [actual: [PulseSent.new(:a_label, :a_name, "a_data"),
                PulseSent.new(:b_label, :b_name, "b_data")]]
    end

    test "compares element by element", %{actual: actual} do
      UT.assert_exact_trace(actual, actual)
      UT.assert_exact_trace(actual, [:a_name, :b_name])
      UT.assert_exact_trace(actual, [[a_name: "a_data"], [b_name: "b_data"]])
      # This is good enough to imply that `assert_log_entry` is used.
    end

    test "differing lengths", %{actual: actual} do
      assertion_fails(
        "The left-hand side has 1 extra value(s).",
        fn ->
          UT.assert_exact_trace(actual, [:a_name])
        end)

      assertion_fails(
        "The right-hand side has 1 extra value(s).",
        fn ->
          UT.assert_exact_trace(actual, [:length, :comparison, :first])
        end)
    end
  end

  describe "assert_trace" do
    setup do
      [actual: [PulseSent.new(:a_label, :a_name, "a_data"),
                PulseSent.new(:b_label, :b_name, "b_data"),
                PulseSent.new(:c_label, :c_name, "c_data")]]
    end

    test "elements can be skipped", %{actual: actual} do
      UT.assert_trace(actual, [:a_name, :b_name])
      UT.assert_trace(actual, [:a_name, [c_name: "c_data"]])
    end

    test "a name not found will produce an error", %{actual: actual} do
      assertion_fails(
        "There is no entry matching `:missing`.",
        [right: :missing],
        fn ->
          UT.assert_trace(actual, [:a_name, :missing])
        end)
    end

    test "a pulse_datanot found will produce an error", %{actual: actual} do
      assertion_fails(
        "There is no entry matching `:c_name`.",
        [right: [c_name: "not c_data"]],
        fn ->
          UT.assert_trace(actual, [:a_name, [c_name: "not c_data"]])
        end)
    end
    
  end
end
