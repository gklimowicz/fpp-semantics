# Requirements
This directory holds the various files used to aid in the requirements definition for the Fortran 202y preprocessor.


# Files

## `INCITS+ISO+IEC+9899-6.10-all.org`
This is a text file (in `org-mode` format) that contains the text from Section 6.10 from all existing versions of the C standards (1999, 2011, 2018, and soon to contain 2024).

Deltas from the one revision to the next are written in pairs of curly braces `{{...}}`.

* `{{`_yyyy_`-` _deleted-text_`}}` means that for the year _yyyy_ standard, _deleted-text_ was removed from the previous revision. The entire construct must be on one physical line.
* `{{`_yyyy_`+` _inserted-text_`}}` means that for the year _yyyy_ standard, _inserted-text_ was inserted into the current revision. The entire construct must be on one physical line.
* `{{`_yyyy_`-` and `{{`_yyyy_`+` on a line by itself indicates multiline text to be deleted or inserted, respectively, for year _yyyy_. These constructs are terminated by a line containing only `}}`.


## `INCITS+ISO+IEC+9899-6.10-`_yyyy_`.org`
A text version of section 6.10 of the C standard for year _yyyy_. These were hand-crafted, but can probably now be auto-generated from `INCITS+ISO+IEC+9899-6.10-all.org`. (In theory, you should be able to export the org-mode text as a PDF file, but the org exporter seems to crash. These crashes are surely due to malformed orgsmode text that hasn't been debugged yet.)


## `INCITS+ISO+IEC+9899-6.10-`_yyyy_`-from-all.org`
A text version of section 6.10 of the C standard for year _yyyy_ auto-generated from `INCITS+ISO+IEC+9899-6.10-all.org`. These aren't yet perfect, but are very close to the hand-crafted versions. (Differences should be limited to footnote numbering.)


## `INCITS+ISO+IEC+9899-1999.txt`
This is a text-only export of the 1999 C programming language standard. It's not in a useful state. I just use it occasionally to grab snippets of text rather than copying from the PDF.


# Makefile targets

## `make requirements.txt`
This target creates a formatted `.txt` version of the `requirements.org` file, via `pandoc`.
We need such a version because the J3 web site only accepts `.txt` and `.pdf` files. We use this version to get various bits of text to put into J3 papers.


## `make INCITS+ISO+IEC+9899-6.10-`_yyyy_`-from-all.org`
Use simple `sed` scripts to create a year _yyyy_ version of section 6.10 of the C standard. It's almost all there except for footnote numbering that would match the handscrafted versions.


## `make clean`
Removes LaTeX temporary files and other cruft.
