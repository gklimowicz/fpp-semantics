# fpp-semantics
Models, code and example programs for the proposed Fortran 202y preprocessor

## fortran-examples
This should be a symlink to a clone of https://github.com/gklimowicz/fortran-examples.
I tried to make it a submodule, and keep it up-to-date with `git submodule` and `--recursive` commands, but it became more trouble than it was worth. It was easier just to symlink to it. Replace my symlink with yous when you clone this repo.

## Makefile
`make all` drives statistics gathering from `fortran-examples`. We only record information for files with preprocessor directives, ignoring those with none.

## all-stats.csv
This file contains collects counts of the number of cpp-like directive lines and each type of directive found. Also tracks uncategorized directives to make sure we didn't miss any directives seen in the files.

## all-stats.xlsx
This file contains a simple statistical analysis of the counts in `all-stats.csv`. It imports the data from the CSV file so I don't have to manually update the count columns. This makes the file large and slow to open and save, but prevents the inevitable mistakes I would make updating it manually.

## bin/fpp-stats
This script drives the statistics generation for each file. It wraps the separate `bin/fpp-stats.awk` file.

## bin/fpp-stats.awk
This simple script collects the statistics generation for a single file. At some point, it will probably be rewritten in something besides AWK.


<!--  LocalWords:  awk csv fpp
 -->
