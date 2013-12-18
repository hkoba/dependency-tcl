dependency.tcl - small tcl(snit) library for Make-like build tool.
====================

This code is a derived work of make.awk, found in [AWK book][awkbook].
See make.awk in [its sourc codes][awkbook-src].

dependency.tcl is implemented on [snit][snit], so you can easily embed this as
sub object/delegation target of snit object tree.

Usage
--------------------

```tcl

# Create an instance.
Dependency dep

# Add dependencies. (You can use target($@), head of dep($<) and alldeps($^))
dep add a.o {a.c a.h} {cc -c $< -o $@}
dep add b.o {b.c b.h} {cc -c $< -o $@}
dep add b.o {b.c b.h} {cc -c $< -o $@}
dep add main.o {main.c a.h b.h c.h} {cc -c $< -o $@}
dep add prog {main.o a.o b.o c.o} {cc $^ -o $@}

# Shortcut proc to use cc as exec gcc
proc cc args {exec gcc {*}$args}

# Then start building.
dep update prog

```

### dep add $target $deplist $action

Add dependency and its building-action.

### dep update $target

Start building $target.

### dep names

returns all known targets


Options
--------------------

### -dryrun $bool

### -quiet $bool

### -debug $bool


[awkbook]: http://www.cs.bell-labs.com/cm/cs/awkbook/
[awkbook-src]: http://www.cs.bell-labs.com/cm/cs/who/bwk/awkcode.txt
[snit]: http://tcllib.sourceforge.net/doc/snitfaq.html
