Affordance
: As a descriptive term, used in the psychology sense: what the
environment offers the individual. Also a particular type of *cluster*
that receives data from *Affordance Land*. Affordance Land generates
named data. The same-named affordance routes the data to other,
downstream clusters.

Affordance Land
: As Gibson puts it in his 1979 book, *affordances* are somewhere
between objective and subjective. They originate in features of the
physical world, but they don't properly exist separate from the
organism that perceives them. Metaphorically, it is affordances that
the app animal perceives. I'm extending that to suppose that all app
animal actions are about creating new affordances (perhaps for the
app-animal itself, perhaps for the user).

: In implementation terms, Affordance Land can send affordances into
the *network* when the app-animal *focuses* on it. These are messages
that are requested: "I am focused on the text of this paragraph;
please send any relevant affordances into the network." But
affordances can also be generated asynchronously, by "noticing
something out of the corner of my eye". For example, movement of the
cursor into a new paragraph will generate an affordance that causes
the app animal to focus on that new paragraph.

Cluster
: A cluster represents a group of neurons that act together to respond
to a *pulse* by calculating a function and sending the result to
downstream clusters. In addition to data from the pulse, the cluster
may use some stored configuration information. All clusters run
asynchronously from other clusters. Clusters may be implemented by
modules or maps of named functions.

: A **linear** cluster represents a plain function: each pulse spawns
an independent Elixir process, which exits immediately after sending
its result downstream.

: A **circular** cluster is a cluster that (conceptually) has a
circular connection of neurons that keeps the cluster active. Such a
cluster stores a bit of mutable state, and that state might be used in
the computation following a pulse. For example, a cluster might
remember the results of its last calculation and only send a *pulse*
downstream if the value changes. Circular clusters "weaken" over time
and eventually become inactive. (The Elixir process exits.) However,
incoming pulses can strengthen a cluster, so some could have
indefinite lifespans.

Focus: 
: Certain *clusters* will at times act to focus on a part of the
*Affordance Land*. That will cause new, now relevant *affordances* to
flow into the *network*.

Network: A structure of interconnected **clusters** that interact with
**Affordance Land**: by receiving incoming **affordances** and acting
(on the output side) to produce new affordances.

Trace
: A linear sequence of _clusters_. Each cluster is downstream of its
  predecessor, meaning it receives *pulses* from it. Traces are
  combined to form a *network*.
