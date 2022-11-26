# fpp-semantics
Models, code and example programs for the proposed Fortran 202y preprocessor

## ALL_F
This is a list of oll Fortran files in all the `fortran-examples` projects.

## ALL_P
This is thi list of all Fortran projects we are tracking (just based on the top-level directory names in `fortran-examples`).

## fortran-examples
This is a clone of https://github.com/gklimowicz/fortran-examples.
This repository consists solely (for now) of git submodules that reference the original source repos  for the projects.

It currently contains about 28 million lines of code, which contian about 370,000 lines of preprocessor directives.

## Makefile
Drives statistics gathering from `fortran-examples`. Collects the number of lines per Fortran file, the number of cpp-like directive lines, and a papulation count of each type of directive found. Also tracks uncategorized directives to make sure widn't miss anything seen in nature.

## ALL_STATS.xlsx
A simple analysis of the raw statistics captured in `ALL_STATS.csv`. Besides the counts, we have info about the percentage of lines of each kind of directive in each file.

## PROJ_STATS.xlsx
This doesn't exist yet, but it would be nice to compute the per-repo statistics as well.
