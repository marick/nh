### Suffixes

A particular struct, such as `CircularProcess`, may be referred to
both as the struct itself and a pid that names a process that uses the
struct as its mutable state. Because I kept confusing the two, I
established this convention that structures should be named
`s_<structure>` and pids `p_<structure>`. 

Similarly, there's sometimes a question of whether a name refers to
the *field* of a structure or a *lens* that refers to that
field. Therefore, lenses begin with `l_`.

When it's not clear that a name is bound to a function, it begins with `f_`. A function-making function is prefixed with `mkfn_`. 

Not super-happy about reinventing
[Hungarian Notation](https://en.wikipedia.org/wiki/Hungarian_notation),
but oh well. 

I will, as whim takes me, break the conventions or not convert old code.


### GenServer use

A GenServer's code is typically divided into two sections. The first
are functions that run in a sender's process. They're syntactic sugar
around, typically, a `GenServer.call`.

The second runs inside the GenServer's (the receiver's) process. They look weird,
like `handle_call(pattern_for_message_x, _from, state)`. 

The point of the App Animal is to use asynchronous messaging almost
exclusively. Making the module looke like a regular model with
ordinary functions hides the asynchrony and I think is confusing. So
I'd prefer not to use those sender functions. However, there's no way
to attach doc strings to the individual `handle_cast` clauses so Oh Well.

However, I name them to emphasize their role.

### Naming the module under tests

When a test file is all about a particular module, I'll often alias
the module _U_nder _T_test to `UT`. I don't know if that's an OK idea
or a bad idea that's a habit. Given that I don't have a refactoring
IDE, it makes my ever-present name changes slightly less annoying and
less of a sprawling commit.

### The System.Pulse structure

The Switchboard and the individual clusters communicate with
`System.Pulse` structures. For convenience, the test support functions
in `ClusterCase` create and decode those structures so that tests can
be written in terms of raw data. There are (will be) exceptions in the
case of Pulses of non-`normal` type.

When it comes to Affordance Land:

* actions sent *into* it from ActionEdges are not wrapped in `Pulse`.
* actions sent *from* it to PerceptionEdges *are* wrapped in a `Pulse`.

### Affordances and their names

An affordance has a name, which is the same as the name of the
`PerceptionEdge` that receives it. The name is used to hook the two
together. That is, whereas cluster-to-cluster communication happens by:

1. starting at the sending cluster,
2. looking up the "downstream" clusters, and
3. sending the same Pulse to each of them.

... Affordance Land to cluster communication happens by sending a
pulse to the cluster with the same name as the affordance.


