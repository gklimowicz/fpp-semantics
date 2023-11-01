# fpp-semantics
Models, code and example programs for the proposed Fortran 202y preprocessor

## fortran-examples
This is a submodule clone of https://github.com/gklimowicz/fortran-examples.

See that project for details on how it is maintained.

We use it here merely as input to the statistics-gathering process. To update to the most current examples, run `make update`.

# Makefile

## `make all`
`make all` drives statistics gathering from `fortran-examples`. We only record information for files with preprocessor directives, ignoring those with none.

# stats.csv
This file contains collects counts of the number of cpp-like directive lines and each type of directive found. Also tracks uncategorized directives to make sure we didn't miss any directives seen in the files.

# stats.xlsx
This file contains a simple statistical analysis of the counts in `all-stats.csv`. It imports the data from the CSV file so I don't have to manually update the count columns. This makes the file large and slow to open and save, but prevents the inevitable mistakes I would make updating it manually.

# Helper programs

## bin/fpp-stats
This script drives the statistics generation for each file. It wraps the separate `bin/fpp-stats.awk` file.

## bin/fpp-stats.awk
This simple script collects the statistics generation for a single file. At some point, it will probably be rewritten in something besides AWK.

## bin/update-stats
Incrementally update `fpp-stats` for files added or changed.

<!--  LocalWords:  awk csv fpp
 -->
