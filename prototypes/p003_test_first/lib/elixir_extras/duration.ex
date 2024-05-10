alias AppAnimal.Duration

defmodule Duration do
  @moduledoc """
  Time expressed in discrete units.

  `quantum/0` and `quanta/1` are abstract units of time. One quantum is the
  interval at which circular clusters "throb".

  Note: tests frequently want throbbing to go faster: every two milliseconds, say, rather
  than 100.

       configuration throb_interval: 2 do...

  Alternately, tests may want manual control over when throbs are delivered to a cluster.
  In that case:

       configuration throb_interval: Duration.foreverish

  When a test controls the throb interval, it should avoid using these functions.
  Use absolute numbers (like 2). If the throb_interval is 2 millis, `seconds 2` will
  still return 20 rather than the 1000 you might expect.
  """

  @type t :: integer

  def quantum(), do: 100 # milliseconds
  def quanta(n), do: n * quantum()

  def seconds(n), do: trunc(n * 1000 / quantum())
  def foreverish(), do: seconds(10_000_000)   # four months
  def frequent_glance, do: seconds(2)
end
