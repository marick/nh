#### Action

An *action* is a data structure sent from a *cluster* into *affordance
land*. It contains a name and some data.

#### Action Edge

An Action Edge is a *cluster* that sends an *action* into Affordance Land.

#### Affordance

As a descriptive term, used in the psychology sense:
what the environment offers the individual. Affordances are received from *Affordance Land* by 
*perception edges*. *Action edges* change Affordance Land to present new affordances to either
some later perception edge or to the user.

`Affordance` also loosely refers to the pulse sent to the 
perception edge.

#### Affordance Land

As Gibson puts it in his 1979 book, *affordances* are somewhere
between objective and subjective. They originate in features of
the physical world, but they don't properly exist separate from
the organism that perceives them. Metaphorically, it is
affordances that the app animal perceives. I'm extending that to
suppose that all app animal actions are about creating new
affordances (perhaps for the app-animal itself, perhaps for the
user).

In implementation terms, Affordance Land can send pulses or  affordances into the
*network* of *clusters*. These are of two types:

* affordances that are requested: "I am focused on the text of this
paragraph; please send any relevant affordances into the network."

* But affordances can also be generated asynchronously, by "noticing
something out of the corner of my eye". For example, movement of the
cursor into a new paragraph will generate an affordance that causes
the app animal to focus on that new paragraph.

#### Age Out

*Circular clusters* have a strength (or hit points). It increases or decreases while
the cluster is active. If it drops to zero, the process "ages out" or
causes itself to exit.

#### Cluster

A cluster represents a group of neurons that act together to respond
to a *pulse* by calculating a function and sending the result to
downstream clusters. All clusters run
asynchronously from other clusters. 

A **linear** cluster represents a plain function: each pulse spawns an
independent Elixir process, which exits immediately after sending its
result downstream. As far as anything external to the task can tell,
the cluster is always *waiting* to be provoked to instantaneously
calculate something.

A **circular** cluster is a cluster that (conceptually) has a circular
connection of neurons that keeps it active. I whimsically
call this "throbbing", intended to convey the idea that
self-reinforcing waves of activation flood across the cluster at
intervals.

Such a cluster stores a bit of mutable state, and that state might be
used in the computation following a pulse. For example, a cluster
might remember the results of its last calculation and only send a
*pulse* downstream if the value changes.

As clusters throb, they count down to to their death, when they
exit. (Perhaps later to be reborn/reactivated.) However, incoming
pulses can increase a cluster's *strength*, so some might
never end up exiting.

#### Delay 

A delay contains a duration and a *pulse*. After the duration, the
*timer* sends the pulse to the *cluster* that requested the delay.

#### Downstream

Any *cluster* is a node in a *network* of clusters. Any cluster has a
series of outgoing edges. Think of them as axons that connect to other
clusters. The "downstream" of a cluster is the transitive closure of
all the out-edges. 

When a cluster finishes a computation, it sends *pulses*
downstream. (It may also send *actions* into affordance-land or
*delays* into the global timer, but they are not considered part of
its downstream. You can think a *perception edge's* downstream as
extending to include terminal *action edges*.

Note that clusters can have different types. For example, a cluster
might produce both an ordinary ("default") cluster and a "suppress"
cluster. The two clusters will be routed to different recipient
clusters.

#### Focus

Certain *clusters* will at times act to focus on a part of the
*Affordance Land*. That will cause new, now relevant *affordances* to
flow into the *network*.

#### Network

A structure of interconnected *clusters* that interact with
*Affordance Land* by receiving incoming *affordances* and acting
(on the output side) to produce new affordances.

#### Perception Edge

A type of *cluster* that receives an *affordance* (a *pulse*) from
*Affordance Land*. Each affordance is named by the perception edge
that receives it. All the perception edge does is fan the pulse out to
downstream clusters.

#### Pulse

Pulses represent the act of sending an Elixir message
*downstream*. They carry some amount of data (usually small). A pulse
represents what, in a real brain, is the combined effect of the
electrical ("action") potentials sent down axons by a number of
neurons (which neurons I'm lumping together into a "*cluster*").

#### Strength

A *circular cluster* has, at any time, a given strength. The cluster
*throbs* at a certain interval, counting down its strength. However,
*pulses* may increase the cluster's strength.

#### Throbbing

When the process behind a *circular cluster* is alive, it is referred to
as "throbbing". This evokes the periodic self-reinforcement of the
cluster. When a circular cluster hasn't ever been started, or when
it's "aged out" because of a lack of work to do, it's called *waiting*.

#### Timer

There is a single timer process that causes *circular clusters* to
*throb*. Centralizing throbbing makes it easy to speed it up in
tests. No cluster is can be aware that it's throbbing in rough
synchrony with other clusters; as far as it can tell, it's marching to
its own beat.

#### Trace

A linear sequence of _clusters_. The first cluster sends its *pulse* to the
second, which calculates on it. If it produces a pulse, that pulse is
sent to the third.

#### Waiting

Thinking of *clusters* as biological, they can be in two states. They
can be sitting around, doing the minimal metabolism to keep themselves
alive, waiting for some *pulse* to arrive and prompt them to start
expending energy on some calculation that will (usually) provoke an
outgoing pulse.

*Linear* clusters are always waiting. Technically, there's a brief
time in which they are performing a calculation; however, no outside
observer can see that. (The calculation is run in an Elixir Task.)

*Circular* clusters are more relevant. The first pulse they receive
starts them working. They continue to remain active (and retain some
state) for some time, waiting to receive a new pulse. If they don't
receive such pulses, they typically "weaken" and eventually go *idle*.
