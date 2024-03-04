# fpp-semantics
Models, code and example programs for the proposed Fortran 202y preprocessor

# Makefile targets

## `make all`
`make all` drives statistics gathering from `fortran-examples`. We only record information for files with preprocessor directives, ignoring those with none.

## stats-directives.csv
This file contains collects counts of the number of cpp-like directive lines and each type of directive found. Also tracks uncategorized directives to make sure we didn't miss any directives seen in the files.


# Other files
## fortran-examples
This is a symbolic link to a separate clone of the https://github.com/gklimowicz/fortran-examples repository.
(This was a submodule, but `fortran-examples` is now ridiculously large, and it doesn't make sense to have two copies lying about.)

See that project for details on how it is maintained.

We use it here merely as input to the statistics-gathering process.


# Helper programs

## bin/fpp-stats
This script drives the statistics generation for each file. It wraps the separate `bin/fpp-stats.awk` file.

## bin/fpp-stats.awk
This simple script collects the statistics generation for a single file. At some point, it will probably be rewritten in something besides AWK.

## bin/update-stats
Incrementally update `fpp-stats` for files added or changed.

<!--  LocalWords:  awk csv fpp
 -->
