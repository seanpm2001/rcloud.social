
# Set the site base output directory. (OUTDIR is usually set by the master Makefile).
ifndef OUTDIR
  OUTDIR = ../out
endif

# Path from the output HTML file to the site root.
# Most topics are cotained in folders in the root of the site so
#  the path to the root is simply '..'.
ifndef BASEPATH
  BASEPATH = ..
endif

# Get the name of the folder containing this Makefile.
ifndef FOLDER
  FOLDER = $(notdir $(CURDIR))
endif

ifndef BASESRC
  BASESRC = ..
endif

ifndef SIDEBAR
  SIDEBAR = ""
endif

# Set the output directory for this topic.
ifndef DSTDIR
  DSTDIR = $(OUTDIR)/$(FOLDER)
endif

# Helpfull abreviations.
HTML     = $(BASESRC)/html
EMPTY_PD = $(BASESRC)/empty.pd
SRC_TYPE = markdown

# Form the header/footer template souce and destination names.
GEN_NAMES   = head body_top body_bottom
GEN_FNS     = $(foreach name,$(GEN_NAMES),$(name).html)
GEN_TMPLS   = $(foreach name,$(GEN_NAMES),$(HTML)/$(name)_template.html)

# The index.html is dependent on the header and footer template files
# DEPEND = $(HTML)/head_template.html $(HTML)/body_top_template.html $(HTML)/body_bottom_template.html
DEPEND = $(GEN_TMPLS)

# If a local file named 'template.html5' exists then use it
# as the template for building index.html
TMPL_FN =template.html5
ifeq ($(strip $(wildcard $(TMPL_FN))),)
  TMPL_FN = $(HTML)/template.html5
endif

DEPEND += $(TMPL_FN)

# If the local markdown file does not exist
# then use dummy.pd
PD_FN = index.pd
ifeq ($(strip $(wildcard $(PD_FN))),)
  PD_FN = $(EMPTY_PD)
  ifeq ($(strip $(wildcard $(BODY_FN))),)
  $(warn No index.pd or body.html was specified for the topic $(FOLDER).)
  endif
endif

DEPEND += $(PD_FN)

# If the local YAML file does not exist then ignore it
YAML_FN = index.yaml
ifeq ($(strip $(wildcard $(YAML_FN))),)
  YAML_FN =
endif

DEPEND += $(YAML_FN)

# The HTML body file used by topics whose body is not generated
# from markdown is body.html
ifneq ($(strip $(wildcard body.html)),)
  SRC_TYPE = markdown
  PD_FN    = body.html
endif

DEPEND += $(BODY_FN)

all : $(DSTDIR)/index.html $(DSTDIR)/index.css


$(DSTDIR)/index.html :  $(DEPEND) $(GEN_FNS)
	mkdir -p $(DSTDIR)
	$(BASESRC)/make_template.sh $(BASESRC)
	pandoc \
	--to=html5 \
	--from=$(SRC_TYPE)  \
	--template=local.template \
	--css=index.css \
	--variable=basepath:$(BASEPATH) \
	--variable=container:$(CONTAINER) \
	--variable=inner-wrapper:$(INNER_WRAPPER) \
	--include-in-header=head.html \
	--include-before-body=body_top.html \
	--include-after-body=body_bottom.html \
	$(PANDOC_OPTS) \
	-o $(DSTDIR)/index.html $(PD_FN) $(YAML_FN)

# Copy the local css file to the destination directory.
$(DSTDIR)/index.css : index.css
	cp index.css $(DSTDIR)/index.css

#
# Use $(BASESRC)/hmtl/*_template.html to generate a include
# files with the CSS,Javscript and href refrences pointing to the correct
# location.
#
# The globally referenced CSS and Javascript files are in folders in
# the site's root directory (css and js). The references to these
# files contained in the <style> and <script> tags of the client HTML
# files will therefore vary depending on their depth in the tree.
# 'href' attributes in the global page headers have a similar problem.
# This means the the references must be generated according to the
# location of the HTML files. We solve this by using a pandoc template
# file containing the global references (html/head_template.html)
# and filling in the path to the 'css' and 'js' folders using a
# variable.  The resulting output, head.html, is then inserted into
# the final output file by using the --include-in-header pandoc
# option.
$(GEN_FNS) : %.html : $(HTML)/%_template.html
	pandoc --template=$< --variable=basepath:$(BASEPATH) --variable=bootstrap:$(BOOTSTRAP) $(TMPL_PANDOC_OPTS) -o $@ $(EMPTY_PD)

# Delete all files generated by this Makefile
clean-all : clean 
	rm -f $(DSTDIR)/index.html
ifneq ($(strip $(realpath $(DSTDIR)/index.css)),index.css)
	rm -f $(DSTDIR)/index.css local.template
endif


clean :
	rm -f $(GEN_FNS) local.template

.PHONY : all clean clean-all $(PHONY_TARGETS)


