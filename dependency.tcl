#!/usr/bin/env tclsh
# -*- coding: utf-8 -*-

# This code is a tcl version of make.awk, originally found in:
# http://www.cs.bell-labs.com/cm/cs/awkbook/
# http://www.cs.bell-labs.com/cm/cs/who/bwk/awkcode.txt

package require snit

snit::type Dependency {
    option -quiet no
    option -dryrun no
    option -debug 0

    variable myDeps [dict create]

    method add {name depends {action ""}} {
	if {[dict exists $myDeps $name]} {
	    error "Node $name is multiply defined!"
	}
	dict set myDeps $name \
	    [dict create depends $depends action $action]
    }

    method update {name {visited ""}} {
	$self age $name
	if {![dict exists $myDeps $name]} {
	    return 0
	}

	set nchanges 0
	dict set visited $name 1
	set depends [dict get $myDeps $name depends]
	foreach succ $depends {
	    if {[set v [dict-default $visited $succ 0]] == 0} {
		$self update $succ $visited
	    } elseif {$v == 1} {
		error "Node $succ and $name are circularly defined!"
	    }
	    if {$options(-debug)} {
		set diff [expr {[$self age $name] - [$self age $succ]}]
		puts "$name-$succ=($diff)"
	    }
	    # If successor is younger than the target,
	    # target should be refreshed.
	    if {[$self age $succ] < [$self age $name]} {
		incr nchanges
	    }
	}
	dict set visited $name 2

	if {$nchanges || [llength $depends] == 0} {
	    $self do-action $name
	    return 1
	}
	return 0
    }

    method do-action name {
	set deps [dict get $myDeps $name depends]
	set map [list \
		     \$@ $name \
		     \$< [lindex $deps 0] \
		     \$^ $deps]
	set action [string map $map [dict get $myDeps $name action]]
	if {!$options(-quiet)} {
	    puts $action
	}
	if {!$options(-dryrun)} {
	    apply [list {self} $action ::] $self
	}
    }

    method age name {
	if {[file exists $name]} {
	    expr {1.0/[file mtime $name]}
	} elseif {[dict exists $myDeps $name]} {
	    return Inf
	} else {
	    error "Unknown node or file: $name"
	}
    }

    #----------------------------------------
    method forget name {
	if {![dict exists $myDeps $name]} {
	    return 0
	}
	dict unset myDeps $name
	return 1
    }

    method names {} {
	dict keys $myDeps
    }
    #----------------------------------------
    proc dict-default {dict key default} {
	if {[dict exists $dict $key]} {
	    dict get $dict $key
	} else {
	    set default
	}
    }
}


if {![info level] && [info script] eq $::argv0} {
    # XXX: to be written.
}
