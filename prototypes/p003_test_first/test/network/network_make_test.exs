# alias AppAnimal.System.Network

# defmodule Network.MakeTest do
#   use ClusterCase, async: true
#   # Although `trace` and similar functions are provided, module-prefix-free, from
#   # ClusterCase, I'll qualify them to make it clearer what's being tested.
#   alias Network.Make, as: UT


#   defp named(names) when is_list(names),
#        do: Enum.map(names, &named/1)
#   defp named(name),
#        do: circular(name)

#   defp downstreams(network) do
#     for one <- deeply_get_all(network, :l_clusters), into: %{} do
#       {one.name, one.downstream}
#     end
#   end
  
#   defp assert_connections(network, field_descriptions) do
#     network
#     |> downstreams
#     |> assert_fields(field_descriptions)
#   end
  
#   describe "building a network (basics)" do
#     test "singleton" do
#       first = linear(:first)
#       assert UT.trace([first]).clusters_by_name.first == first
#     end

#     test "multiple clusters in a row (a 'trace')" do
#       named([:first, :second, :third])
#       |> UT.trace
#       |> assert_connections(first: [:second], second: [:third])
#     end

#     test "can build from multiple disjoint traces" do
#          UT.trace(named([:a1, :a2]))
#       |> UT.trace(named([:b1, :b2]))
#       |> assert_connections(a1: [:a2], a2: [],
#                             b1: [:b2], b2: [])
#     end
#   end

  

#   describe "handling of duplicates" do 
#     test "new value does not overwrite an existing one" do
#       first = linear(:first, & &1+1000)
#       new_first = linear(:first, &Function.identity/1)
#       network = UT.trace([first, new_first])
#       assert network.clusters_by_name.first.calc == first.calc

#       # Note that there's a loop because some version of first appears twice in the
#       # trace.
#       assert network.clusters_by_name.first.downstream == [:first]
#     end

#     test "adding duplicates doesn't overwrite the first cluster, but it makes traces loopy" do
#       [first, second, third] = named([:first, :second, :third])

#       [first, second, first, third, second]
#       |> UT.trace
#       |> assert_connections(first: in_any_order([:second, :third]),
#                             second: [:first],
#                             third: [:second])
#     end

#     test "can add a branch starting at an existing node" do
#       # This is, in effect adding a duplicate
#       UT.trace(named([      :first,              :second_a, :third]))
#       |> UT.extend(     at: :first, with: named([:second_b, :third]))
#       |> assert_connections(first: in_any_order([:second_a, :second_b]),
#                             second_a: [:third],
#                             second_b: [:third])
#     end
#   end


#   describe "helpers" do 
#     test "add_only_new_clusters" do
#       add_only_new_clusters(%{}, [%{name: :one, value: "original"},
#                                      %{name: :two},
#                                      %{name: :one, value: "duplicate ignored"}])
#       |> assert_equals(%{one: %{name: :one, value: "original"},
#                          two: %{name: :two}})
#     end
    
#     test "add_only_new_clusters works when the duplicate comes in a different call" do
#       original = %{one: %{name: :one, value: "original"}}
#       add_only_new_clusters(original, [ %{name: :two},
#                                            %{name: :one, value: "duplicate ignored"}])
#       |> assert_equals(%{one: %{name: :one, value: "original"},
#                          two: %{name: :two}})
#     end
    
#     test "add_downstream" do
#       trace = [first, second, third] = Enum.map([:first, :second, :third], &named/1)
      
#       network =
#         add_only_new_clusters(%{}, trace)
#         |> add_downstream([[first, second], [second, third]])
      
#       assert network.first.downstream == [:second]
#       assert network.second.downstream == [:third]
#       assert network.third.downstream == []
#     end
#   end
# end
