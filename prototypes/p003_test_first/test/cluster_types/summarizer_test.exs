alias AppAnimal.Cluster

defmodule Cluster.SummarizerTest do
  use AppAnimal.Case, async: true

  test "summarizer" do
    cluster = C.summarizer(:example, &String.length/1)

    assert_fields(cluster, id: Identification.new(name: :example, label: :summarizer),
                           name: :example)

    assert cluster.calc.("long") == 4
  end
end
