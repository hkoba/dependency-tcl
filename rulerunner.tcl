#!/usr/bin/env tclsh
# -*- coding: utf-8 -*-

# This code is a tcl version of make.awk, originally found in:
# http://www.cs.bell-labs.com/cm/cs/awkbook/
# http://www.cs.bell-labs.com/cm/cs/who/bwk/awkcode.txt

package require snit
package require struct::list

snit::type RuleRunner {
    option -quiet no
    option -dryrun no
    option -debug 0

    option -known-keys ""; # For user extended keys
    variable myKnownKeysDict []
    typevariable ourRequiredKeysList [set KEYS [list depends action]]
    typevariable ourKnownKeysList [list {*}$KEYS age result]

    variable myDeps [dict create]

    

    # For shorthand
    method add {name depends {action ""} args} {
        $self rule add $name depends $depends action $action {*}$args
    }

    method {rule add} {name args} {
	if {[dict exists $myDeps $name]} {
	    error "Rule $name is multiply defined!"
	}
        set dict [dict create {*}$args]
        if {[set errors [$self rule verify $dict]] ne ""} {
            error "Rule $name has error: $errors"
        }
	dict set myDeps $name $dict
    }

    method {rule verify} dict {
        set errors []
        set missingKeys []
        foreach k $ourRequiredKeysList {
            if {![dict exists $dict $k]} {
                lappend missingKeys $k
            }
        }
        if {$missingKeys ne ""} {
            lappend errors "Mandatory keys are missing: $missingKeys"
        }
        set unknownKeys []
        if {$myKnownKeysDict eq ""} {
            foreach k [list {*}$options(-known-keys) {*}$ourKnownKeysList] {
                dict set myKnownKeysDict $k 1
            }
        }
        foreach k [dict keys $dict] {
            if {![dict exists $myKnownKeysDict $k]} {
                lappend unknownKeys $k
            }
        }
        if {$unknownKeys ne ""} {
            lappend errors "Unknown keys: $unknownKeys"
        }
        set errors
    }

    method update {name {visited ""}} {
	$self age $name
	if {![dict exists $myDeps $name]} {
	    return 0
	}

	set nchanges 0
	dict set visited $name 1
	set depends [dict get $myDeps $name depends]
	foreach pred $depends {
	    if {[set v [dict-default $visited $pred 0]] == 0} {
		$self update $pred $visited
	    } elseif {$v == 1} {
		error "Rule $pred and $name are circularly defined!"
	    }
	    if {$options(-debug)} {
		set diff [expr {[$self age $name] - [$self age $pred]}]
		puts "$name-$pred=($diff)"
	    }
	    # If predecessor is younger than the target,
	    # target should be refreshed.
	    if {[$self age $pred] < [$self age $name]} {
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
	    set resList [apply [list {self rule} $action ::] $self $name]
            if {$resList ne ""} {
                set rest [lassign $resList bool]
                if {$bool} {
                    dict set myDeps age [clock microseconds]
                }
                dict set myDeps result $rest
            }
	}
    }

    method age name {
        if {[dict exists $myDeps $name age]} {
            dict get $myDeps $name age
        } elseif {[file exists $name]} {
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
