#! /usr/bin/make -rRf
#?
#? NAME
#?      Makefile - for EMiR - Event Mappings in Reality
#?
#? DESCRIPTION
#?      Makefile to generate static emir.js and static HTML files.
#?      All data is well defined in  emir.html,  hence it is useed to extract
#?      other informations from there instead of statically defining it here,
#?      for example the tags requiring their own file:  EMiR-FILE-TAGS .
#?      The tags in emir.html used here are marked with following attributes:
#?          empty:true
#?          meta:true
#?          file:true
#?      For details about the generation, see  tag-file-generator.pl .
#?
#? VERSION
#?      @(#) Makefile 1.5 21/03/17 14:12:39
#?
#? AUTHOR
#?      20-apr-20 Achim Hoffmann
#?
# -----------------------------------------------------------------------------

SID             := 1.5

first-target-is-default: help

EMiR-EXE.pl     := ./tag-file-generator.pl
EMiR.html       := ./emir.html
EMiR.js         := ./emir.js
EMiR-PREFIX     := emir-
EMiR.CLOSEhtml  := $(EMiR-PREFIX)closetags.html
empty-pattern   := "/empty:true/&&do{s/\s*'([^']*)'.*/\1/;print}"
meta-pattern    := "/meta:true/&&do{s/\s*'([^']*)'.*/\1/;print}"
file-pattern    := "/file:true/&&do{s/\s*'([^']*)'.*/\1/;print}"
EMiR-FILE-TAGS  := $(shell perl -lane $(file-pattern) $(EMiR.html) | sort -u)
EMiR-TAGS       := $(shell perl $(EMiR-EXE.pl) --list-tags   | sort -u)
EMiR-EVENTS     := $(shell perl $(EMiR-EXE.pl) --list-events | sort -u)

EMiR.files       = $(EMiR-FILE-TAGS:%=$(EMiR-PREFIX)%.html) $(EMiR.js) $(EMiR.CLOSEhtml)

.PHONY: $(EMiR.js) $(EMiR.CLOSEhtml)
.PHONY: $(EMiR.html)
    # avoid "sccs get .." or similar

help:
	@echo "# target description"
	@echo "#-------+------------------------------------------------------"
	@echo " help    WYSIWYG"
	@echo " all     generate all files:"
	@echo "         $(EMiR.files)"
	@echo " emir.js generate $(EMiR.js)"
	@echo " $(EMiR.CLOSEhtml):"
	@echo "         generate $(EMiR.CLOSEhtml)"
	@echo " list    list all known tags and events"

doc: help

$(EMiR-PREFIX)%.html:
	@$(EMiR-EXE.pl) $* > $@
$(EMiR.js):
	@$(EMiR-EXE.pl) --js > $@
$(EMiR.CLOSEhtml):
	@$(EMiR-EXE.pl) --close $(EMiR-TAGS) > $@
$(EMiR.files): Makefile $(EMiR-EXE.pl) $(EMiR.html)

all: $(EMiR.files)

list:
	@echo "# EMiR-FILE-TAGS: $(EMiR-FILE-TAGS)"
	@echo "# EMiR.files:     $(EMiR.files)"
	@echo "# EMiR-TAGS:      $(EMiR-TAGS)"
	@echo "# EMiR-TAGS:      $(EMiR-TAGS)"
	@echo "# EMiR-EVENTS:    $(EMiR-EVENTS)"
