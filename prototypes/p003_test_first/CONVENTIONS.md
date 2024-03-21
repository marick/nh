### Suffixes for structs, pids, and lenses

A particular struct, such as `CircularProcess`, may be referred to
both as the struct itself and a pid that names a process that uses the
struct as its mutable state. Because I kept confusing the two, I
established this convention that structures should be named
`s_<structure>` and pids `p_<structure>`. 

Similarly, there's sometimes a question of whether a name refers to
the *field* of a structure or a *lens* that refers to that
field. Therefore, lenses begin with `l_`.

Not super-happy about reinventing
[Hungarian Notation](https://en.wikipedia.org/wiki/Hungarian_notation),
but oh well.