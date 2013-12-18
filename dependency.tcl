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

    variable myNodes -array {}
    variable myActions -array {}

    method add {name depends {action ""}} {
	set vn myNodes($name)
	if {[info exists $vn]} {
	    error "Node $name is multiply defined!"
	}
	set $vn $depends
	set myActions($name) $action
    }

    method forget name {
	set vn myNodes($name)
	if {![info exists $vn]} {
	    return 0
	}

	unset $vn
	unset myActions($name)
	return 1
    }

    method names {} {
	array names myNodes
    }

    method do-action name {
	set map [list \
		     \$@ $name \
		     \$< [lindex $myNodes($name) 0] \
		     \$^ $myNodes($name)]
	set action [string map $map $myActions($name)]
	if {!$options(-quiet)} {
	    puts $action
	}
	if {!$options(-dryrun)} {
	    apply [list {self} $action ::] $self
	}
    }

    method update {name {visited ""}} {
	set vn myNodes($name)
	$self age $name
	if {![info exists $vn]} {
	    return 0
	}

	set nchanges 0
	dict set visited $name 1
	foreach succ [set $vn] {
	    if {[set v [dict-default $visited $succ 0]] == 0} {
		$self update $succ $visited
	    } elseif {$v == 1} {
		error "Node $succ and $name are circularly defined!"
	    }
	    # 依存先が自分より若い = 自分も若返る必要が有る
	    if {$options(-debug)} {
		puts "$name-$succ=([expr {[$self age $name] - [$self age $succ]}])"
	    }
	    if {[$self age $succ] < [$self age $name]} {
		incr nchanges
	    }
	}
	dict set visited $name 2

	if {$nchanges || [llength [set $vn]] == 0} {
	    $self do-action $name
	    return 1
	}

	return 0
    }

    method age name {
	if {[file exists $name]} {
	    expr {1.0/[file mtime $name]}
	} elseif {[info exists myNodes($name)]} {
	    return Inf
	} else {
	    error "Unknown node or file: $name"
	}
    }

    proc dict-default {dict key default} {
	if {[dict exists $dict $key]} {
	    dict get $dict $key
	} else {
	    set default
	}
    }
}


if {![info level] && [info script] eq $::argv0} {
    
}
