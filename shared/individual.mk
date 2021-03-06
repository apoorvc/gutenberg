
SHELL := /bin/bash
export LATEX_ROOT = /usr/local/texlive/2011
export TEXINPUTS = :$(LATEX_ROOT)/../texmf-local///:$(LATEX_ROOT)

# Executables to call ... 
dvipsCmd := /usr/local/texlive/2011/bin/i386-linux/dvips
latexCmd := $(shell which latex)
ps2pdfCmd := $(shell which ps2pdf)

# Locations ... 

# For historical reasons, the parent of vault, mint etc on the 
# production server was called bank/. But on our local machines, it 
# was changed to be called 'gutenberg'. The environment variable 
# - PRODUCTION_SERVER - identifies the machine as such. It does NOT 
# - in fact, should not - be set on your local machine. Only on the
# production server

Gutenberg := $(if $(PRODUCTION_SERVER), $(HOME)/bank, $(HOME)/workspace/gutenberg-live)
Vault := $(Gutenberg)/vault
Shared := $(Gutenberg)/shared

# Input files - TeX, gnuplots, .sk and the like. Only the answer-key is to be generated 
Scaffolds := $(wildcard $(Shared)/*.tex)
Folder := $(notdir $(CURDIR))
Basename := $(Folder).tex # 123.tex
Plots := $(wildcard *.gnuplot)

# Generated files - all share the same basename as the stitched answer TeX 
Tex := $(patsubst %.tex, %-answer.tex, $(Basename)) # 123-answer.tex
Dvi := $(patsubst %.tex, %-answer.dvi, $(Basename)) # 123-answer.dvi
Ps := $(patsubst %.tex, %-answer.ps, $(Basename)) # 123-answer.ps
Pdf := $(patsubst %.tex, %-answer.pdf, $(Basename)) # 123-answer.pdf
Thumb := $(patsubst %.tex, %-thumb.jpeg, $(Basename)) # 123-thumb.jpeg
Preview := $(patsubst %.tex, %-answer.jpeg, $(Basename)) # 123-answer.jpeg

#PHONY : plot prepare dvi ps

$(Thumb) : $(Preview)
	@echo "[ preview -> thumbnail ]"
	@convert $^ -resize 120x120 $@
ifeq ($(MAKELEVEL),0)
	@echo "Running atomically"
	@if [[ ! $$PRODUCTION_SERVER ]] ; then gs $(Pdf) ; fi
endif

$(Preview) : $(Pdf)
	@echo "[ pdf -> preview ]"
	@gs -sDEVICE=jpeg -r700 -o $@ $^
	@convert $@ -resize 600x800 $@

$(Pdf) : $(Ps)
	@echo "[ps -> pdf]: $@ with [ps2pdfCmd] = $(ps2pdfCmd)"
	@$(ps2pdfCmd) $(Ps)

$(Ps) : $(Dvi)
	@echo "[dvi -> ps]: $@ with [dvips] = $(dvipsCmd)"
	@$(dvipsCmd) -q $(Dvi)

$(Dvi) : $(Tex) 
	@echo "[TeX -> dvi]: $@ with [latex] = $(latexCmd)"
	@$(latexCmd) $(Tex)

$(Tex) : $(Plots) $(Scaffolds) question.tex
	@echo "[plotting]: $(Plots)" && gnuplot $(Plots)
	-@echo "[stitching]: $@" && rm -f $@
	@for j in preamble printanswers doc_begin ; do cat $(Shared)/$$j.tex >> $@ ; done
	@cat question.tex >> $@
	@for j in doc_end ; do cat $(Shared)/$$j.tex >> $@ ; done

clean :
	@rm -f $(Folder)* && rm -f *.table

