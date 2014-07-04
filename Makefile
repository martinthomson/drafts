ifeq "$(shell uname -o 2>/dev/null)" "Cygwin"
    CYGPATH := cygpath --windows
else
    CYGPATH := echo
endif

BASE := $(lastword $(basename $(wildcard draft-*.xml)))
XML := ${BASE}.xml
DTD := rfc2629.dtd
XSLT := rfc2629.xslt

# SAXON := java -jar '$(subst \,\\,$(shell ${CYGPATH} ${TOP}/saxon8.jar))'
VALIDATE := ${TOP}/validate
SAXON := java -jar '$(shell ${CYGPATH} ${TOP}/saxon8.jar)'
ifeq (,$(shell which xml2rfc 2>/dev/null))
XML2RFC ?= ${TOP}/webxml2rfc.sh
else
XML2RFC ?= xml2rfc
endif
XSLT_HOME := ${TOP}/rfc2629xslt
HTML_XSLT := false
IDNITS := ${TOP}/idnits/idnits

.PHONY: default all clean
ifeq (,${TOP})
### Targets for the top dir
TOP := .
default: all
all::
	for i in *; do [ ! -f $$i/Makefile ] || $(MAKE) -C $$i txt html || exit $$?; done
clean::
	for i in *; do [ ! -f $$i/Makefile ] || $(MAKE) -C $$i clean; done

GHPAGES_TMP := /tmp/ghpages$(shell echo $$$$)
.TRANSIENT: ${GHPAGES_TMP}
GITORIG := $(shell git branch | grep '*' | cut -c 3-)

IS_LOCAL := $(if ${TRAVIS},true,)
ifeq (master,$(TRAVIS_BRANCH))
IS_MASTER := $(findstring false,${TRAVIS_PULL_REQUEST})
else
IS_MASTER := true
endif

ghpages: all
ifneq (,$(or $(IS_LOCAL),$(IS_MASTER)))
	mkdir ${GHPAGES_TMP}
	find ${TOP} -type f \( -name '*.html' -o -name '*.txt' \) -exec cp {} ${GHPAGES_TMP} \;
	@find ${GHPAGES_TMP}
ifeq (true,${TRAVIS})
	git config user.email "martin.thomson@gmail.com"
	git config user.name "Travis CI Builder"
	git checkout -q --orphan gh-pages
	git rm -qr --cached .
	git clean -qfd
	git pull -qf origin gh-pages --depth=5
else
	git checkout gh-pages
	git pull
endif
	mv -f ${GHPAGES_TMP}/* ${TOP}
	./mkindex > index.html
	git add ${TOP}/*.txt ${TOP}/*.html
	if test `git status -s | wc -l` -gt 0; then git commit -m "Script updating page."; fi
ifeq (false,$(TRAVIS_PULL_REQUEST))
	@git push https://$(GH_TOKEN)@github.com/martinthomson/drafts.git gh-pages
endif
ifneq (true,${TRAVIS})
	git checkout ${GITORIG}
endif
	-rm -rf ${GHPAGES_TMP}
endif

else
### Targets for subdirs
.PHONY: extra nits validate submit tag
default: txt

extra: default html pdf xhtml svg nr unpg
all:: extra nits validate

REV_CURRENT := $(shell git tag | grep "${BASE}" | tail -1 | sed -e"s/.*-//")
ifeq "${REV_CURRENT}" ""
REV_NEXT ?= 00
else
REV_NEXT ?= $(shell printf "%.2d" $$((1${REV_CURRENT}-99)))
endif
BASE_NEXT := ${BASE}-${REV_NEXT}

.PHONY: txt html xhtml pdf svg nr unpg
ifeq (,$(shell grep 'date' ${BASE}.xml | grep 'year="$(shell date +%Y)"' 2>&1))
txt:: skipdir
html:: skipdir
xhtml:: skipdir
pdf:: skipdir
svg:: skipdir
nr:: skipdir
unpg:: skipdir
else
txt:: ${BASE}.txt
html:: ${BASE}.html
xhtml:: ${BASE}.xhtml
pdf:: ${BASE}.pdf
svg:: ${BASE}.svg
nr:: ${BASE}.nr
unpg:: ${BASE}.unpg
endif

.TRANSIENT: tmp.fo ${BASE}.svg~

ifeq "${HTML_XSLT}" "false"
extra_css := ${TOP}/lib/style.css
css_content = $(shell cat $(extra_css))
%.htmltmp: %.xml $(extra_css)
	${XML2RFC} --html $< -o $@
else
%.htmltmp: %.xml ${DTD} ${XSLT}
#	${SAXON} '$(subst \,\\,$(shell ${CYGPATH} $<))' '$(subst \,\\,$(shell ${CYGPATH} ${XSLT_HOME}/${XSLT}))' > $@
	${SAXON} $< ${XSLT_HOME}/${XSLT} > $@
endif

%.html: %.htmltmp $(extra_css)
	sed -e's~</style>~</style><style tyle="text/css">$(css_content)</style>~' $< > $@

%.xhtml: %.xml ${DTD} ${XSLT}
	${SAXON} '$(subst \,\\,$(shell ${CYGPATH} $<))' '$(subst \,\\,$(shell ${CYGPATH} ${XSLT_HOME}/rfc2629toXHTML.xslt))' > $@

%.fo: %.xml ${DTD} ${XSLT} rfc2629-xhtml.ent rfc2629-other.ent
	${SAXON} $< ${XSLT_HOME}/rfc2629toFO.xslt > tmp.fo
	${SAXON} tmp.fo ${XSLT_HOME}/xsl11toFop.xslt > $@
	-rm -f tmp.fo

%.pdf: %.fo
	${FOP} $< -pdf $@

%.svg: %.fo
	${FOP} $< -svg $@
# The following is for the benefit of inkscape.
	perl -pi~ -e 's/fill:blue;visibility:hidden/fill:none;visibility:hidden/g' $@
	-rm -f $@~

%.ps: %.fo
	${FOP} $< -ps $@

%.txt: %.xml
	${XML2RFC} $< $@

%.nr: %.xml ${DTD} ${XSLT}
	${XML2RFC} $< $@

%.unpg: %.xml ${DTD} ${XSLT}
	${XML2RFC} $< $@

${XSLT}: ${XSLT_HOME}/${XSLT}
	cp $< $@

${DTD}:  ${XSLT_HOME}/${DTD}
	cp $< $@

rfc2629-xhtml.ent: ${XSLT_HOME}/rfc2629-xhtml.ent
	cp $< $@

rfc2629-other.ent: ${XSLT_HOME}/rfc2629-other.ent
	cp $< $@

.PHONY: nits validate skipdir
nits: ${BASE}.txt
	${IDNITS} --verbose $<

validate: $(wildcard xml/*.xml example*.xml)
	$(TOP)/xmlschema/build-strict
	${VALIDATE} $^

skipdir:
	@echo Skipping old ${BASE}.xml

submit:: ${BASE_NEXT}.txt

${BASE_NEXT}.xml: ${BASE}.xml
	sed -e"s/${BASE}-latest/${BASE_NEXT}/" < $< > $@

SUFFIXES := txt html xhtml unpg nr ps svg pdf
clean::
	-rm -f $(addprefix ${BASE}-[0-9][0-9].,xml ${SUFFIXES}) $(addprefix ${BASE}.,${SUFFIXES}) *.fo rfc2629-*.ent *.stackdump rfc2629.* *~

endif


tag:
	git tag ${BASE_NEXT}
retag:
	git tag -f ${BASE}-${REV_CURRENT}

