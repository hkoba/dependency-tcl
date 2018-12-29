#!/bin/sh
# the next line restarts using tclsh \
exec tclsh "$0" ${1+"$@"}

package require tcltest
namespace import ::tcltest::*
runAllTests
