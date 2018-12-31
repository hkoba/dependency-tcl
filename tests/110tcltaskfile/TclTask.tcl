#!/usr/bin/env taskrunner.tcl
# -*- coding: utf-8 -*-

puts "OK"

proc cc args {exec gcc {*}$args}

dep add a.o {a.c a.h} {cc -c $< -o $@}

foreach k {b c} {
    dep add $k.o "$k.c $k.h" {cc -c $< -o $@}
}

dep add main.o {main.c a.h b.h c.h} {cc -c $< -o $@}
dep add prog {main.o a.o b.o c.o} {cc $^ -o $@}

puts [list ::argv $::argv]

if {$::argv eq ""} {
    dep update prog

} else {
    switch [lindex $::argv 0] {
        clean {
            file delete {*}[dep target list]
        }
        default {
            error "No such command: $::argv"
        }
    }
}
