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
#?      @(#) Makefile 1.3 21/03/17 12:32:02
#?
#? AUTHOR
#?      20-apr-20 Achim Hoffmann
#?
# -----------------------------------------------------------------------------

SID             := 1.3

first-target-is-default: help

EMiR-EXE.pl     := ./tag-file-generator.pl
EMiR.html       := ./emir.html
EMiR.js         := ./emir.js
EMiR-PREFIX     := emir-
empty-pattern   := "/empty:true/&&do{s/\s*'([^']*)'.*/\1/;print}"
meta-pattern    := "/meta:true/&&do{s/\s*'([^']*)'.*/\1/;print}"
file-pattern    := "/file:true/&&do{s/\s*'([^']*)'.*/\1/;print}"
EMiR-FILE-TAGS  := $(shell perl -lane $(file-pattern) $(EMiR.html) | sort -u)

EMiR.files       = $(EMiR-FILE-TAGS:%=$(EMiR-PREFIX)%.html) $(EMiR.js)

help:
	@echo " all:    generate all files:"
	@echo "         $(EMiR.files)"

doc: help

$(EMiR.js):
	@$(EMiR-EXE.pl) --js > $@
$(EMiR.files): Makefile $(EMiR-EXE.pl) $(EMiR.html)
$(EMiR-PREFIX)%.html:
	@$(EMiR-EXE.pl) $* > $@

all: $(EMiR.files)
