#### Action Edge

#### Affordance

As a descriptive term, used in the psychology sense:
what the environment offers the individual. Affordances are received from *Affordance Land* by 
*perception edges*. *Action edges* change Affordance Land to present new affordances to either
some later perceptiuon edge or to the user.

#### Affordance Land

As Gibson puts it in his 1979 book, *affordances* are somewhere
between objective and subjective. They originate in features of
the physical world, but they don't properly exist separate from
the organism that perceives them. Metaphorically, it is
affordances that the app animal perceives. I'm extending that to
suppose that all app animal actions are about creating new
affordances (perhaps for the app-animal itself, perhaps for the
user).

In implementation terms, Affordance Land can send affordances into
the *network* when the app-animal *focuses* on it. These are messages
that are requested: "I am focused on the text of this paragraph;
please send any relevant affordances into the network." But
affordances can also be generated asynchronously, by "noticing
something out of the corner of my eye". For example, movement of the
cursor into a new paragraph will generate an affordance that causes
the app animal to focus on that new paragraph.

#### Age Out

*Circular clusters* have a lifespan. It increases or decreases while
the cluster is active. If it drops to zero, the process "ages out" or
causes itself to exit.

#### Cluster

A cluster represents a group of neurons that act together to respond
to a *pulse* by calculating a function and sending the result to
downstream clusters. In addition to data from the pulse, the cluster
may use some stored configuration information. All clusters run
asynchronously from other clusters. Clusters may be implemented by
modules or maps of named functions.

A **linear** cluster represents a plain function: each pulse spawns an
independent Elixir process, which exits immediately after sending its
result downstream. As far as anything external to the task can tell,
the cluster is always *waiting* to be provoked to (instantaneously)
calculate something.

A **circular** cluster is a cluster that (conceptually) has a circular
connection of neurons that keeps the cluster active. I whimsically
call this "throbbing", intended to convey the idea that
self-reinforcing waves of activation flood across the cluster at
intervals.

Such a cluster stores a bit of mutable state, and that state might be
used in the computation following a pulse. For example, a cluster
might remember the results of its last calculation and only send a
*pulse* downstream if the value changes.

As clusters throb, they count down to to their death, when they
exit. (Perhaps later to be reborn.) However, incoming pulses can
increase a cluster's strength or *lifespan*, so some might never end
up exiting.

#### Downstream

A cluster sends *pulses* to other clusters. They are its "downstream".

#### Edges

Typically a cluster will receive a pulse from one cluster, run a
calculation, and send the result *downstream*. However, some clusters
receive an *affordance* from the *Affordance Land* or send pulses into
it. (That latter is shorthand for metaphorically activating motor
neural clusters that act on the world.

#### Focus

Certain *clusters* will at times act to focus on a part of the
*Affordance Land*. That will cause new, now relevant *affordances* to
flow into the *network*.

#### Idle

A *cluster* is idle if it's consuming no resources but is waiting for
a *pulse*. In Elixir terms, this means it has no associated running
process.

#### Lifespan

A *circular cluster* is "born" and may eventually die. The cluster
*throbs* at a certain interval, counting down its lifespan. However,
*pulses* may increase the cluster's lifespan.

#### Network

A structure of interconnected **clusters** that interact with
**Affordance Land**: by receiving incoming **affordances** and acting
(on the output side) to produce new affordances.

#### Perception Edge

A type of *cluster* that receives an *affordance* (an Elixir message)
from *Affordance Land*. Typically, it forwards the message to its
downstream clusters.

#### Pulse

Pulses represent the act of sending an Elixir message
*downstream*. They carry some amount of data (usually small). A pulse
represents what, in a real brain, is the combined effect of the
electrical ("action") potentials sent down axons by a number of
neurons (which neurons I'm lumping together into a "*cluster*".

#### Throbbing

When the process behind a circular cluster is alive, it is referred to
as "throbbing". This evokes the periodic self-reinforcement of the
cluster. When a circular cluster hasn't ever been started, or when
it's died off because of a lack of work to do, it's called *waiting*.

#### Trace

A linear sequence of _clusters_. Each cluster is downstream of its
predecessor, meaning it receives *pulses* from it. Traces are
combined to form a *network*.


#### Waiting

Thinking of clusters as biological, they can be in two states. They
can be sitting around, doing the minimal metabolism to keep themselves
alive, waiting for some *pulse* to arrive and prompt them to start
expending energy on some calculation that will (usually) provoke an
outgoing pulse.

*Linear* clusters are always waiting. Technically, there's a brief
time in which they are performing a calculation; however, no outside
observer can see that.

*Circular* clusters are more relevant. The first pulse they receive
starts them working. They continue to remain active (and retain some
state) for some time, waiting to receive a new pulse. If they don't
receive such pulses, they typically "weaken" and eventually go *idle*.
