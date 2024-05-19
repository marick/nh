### Prefixes

A particular struct, such as `Cluster.Circular`, may be referred to
both as the struct itself and a pid that names a process that uses the
struct as its mutable state. Because I kept confusing the two, I
established this convention that structures should be named
`s_<structure>` and pids `p_<structure>`. 

When it's not clear that a name is bound to a function, it begins with
`f_`. A function-making function is prefixed with `mkfn_`.

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
I'd prefer not to use those sender functions.

The `AppAnimal.StructServer` model supports that. It defines two
(overridable) functions, `cast` and `call`. A call of this form is:

    Switchboard.cast(p_switchboard, :distribute_pulse,
                                    carrying: pulse,
                                    to: [destination_name])
                                                       
`cast` converts that to this:

    GenServer.cast(p_switchboard, {:distribute_pulse,
                                   carrying: pulse, to: [destination_name]})

However, certain GenServers that use `call` heavily, like
`AppAnimal.NetworkBuilder`, are more conventional in style and are
called like this:

    NB.branch(pid, at: name, with: list)
    
A disadvantage of this approach is that it gives no place to put
`@doc` strings that will appear in the results of `mix docs`. (The
`handle_cast` versions do not appear in module docs.)


### Naming the module being tested

When a test file is all about a particular module, I'll often alias
the module _U_nder _T_test to `UT`. I don't know if that's an OK idea
or a bad idea that's a habit. Given that I don't have a refactoring
IDE, it makes my ever-present name changes slightly less annoying and
less of a sprawling commit.


### Moveables

`Pulse` structures carry data to clusters. `Actions` carry data into
`AffordanceLand`.  `Affordance` structures carry data out of
`AffordanceLand`. `Delay` structures request behavior from the
`Timer`.

All of these structures implement the `Moveable` structure.

### Affordances and their names

An affordance has a name, which is the same as the name of the
`PerceptionEdge` that receives it. The name is used to hook the two
together. That is, whereas cluster-to-cluster communication happens by:

1. starting at the sending cluster,
2. looking up the "downstream" clusters, and
3. sending the same Pulse to each of them.

... Affordance Land to cluster communication happens by sending a
`Pulse` to the cluster with the same name as the affordance.


### Map names

Use `x_to_y`. That's somewhat like the definition of a function as a
*map* from a domain to a range.

    field :name_to_id, %{atom => Cluster.Identification.t}, default: %{}

### Lens use

I'm still working out how to use lenses, but I'm converging on something like this:

Structures defined with `typedstruct` and the `TypedStructLens` plugin
have lenses for each field. Generally speaking, I avoid composed
lenses that "reach into" a nested structure. That is, you won't often see
a function within a module with a variable defined like this:

    lens = Network.linear_clusters() |> Network.LinearSubnet.cluster_named(cluster.name)

Instead, `Network` will have a top-level lens with that definition, so that its internal
structure can be ignored by its clients. 

Generally, lenses are used like `Map` functions, but with the
`DepthAgnostic` module (universally aliased to `A`). That looks like
this:

    A.put(s_circular, :max_age, 12)
    
Although `:max_age` looks like a field name, it's actually the name of
a lens that reaches into a substructure. As far as the client knows,
it's at the top level.


Lens functions can take arguments, in which case the function is called like this:

    A.one!(s_network, cluster_named(name))
