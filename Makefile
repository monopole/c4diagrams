# General idea
#
#    * Maintain diagrams as human-readable, human-editable textual
#      instructions stored in github.
#
#    * Generate images (ideally svg's) from the diagram instructions at will
#      A Makefile or CI/CD is a good place to keep these instructions.
#
#    * Optional: Use graphical tool to do layout (since auto-layout usually looks bad).
#
#    * Include these images in markdown.
#
#
#   The basic markdown syntax for image import is
#     ![my fancy diagram](./some/diagram.svg "My Fancy Diagram")
#
#   To get a desired size, use a raw HTML image tag, e.g.
#    <img src="./some/diagram.svg" alt="my fancy diagram" title="My Fancy Diagram" width="150"/>
#

# Mermaid is a pile of javascript that converts textual descriptions
# of diagrams into .svg files.
#
# FWIW, mermaid can also convert a specially annotated markdown file
# into a new markdown file with textually embedded diagram descriptions
# replaced by image tags.  This approach is unwieldy as soon as the
# diagrams get to be more complex than just two or three boxes.
# Also this technique forces use of autolayout, since layout programs
# cannot read/write diagrams embedded in this way.
# It's best to keep the diagrams in their own files, and have
# the markdown use image tags to pull them in.
#
# Mermaid's notation for c4 diagrams is it's own, and not the same as,
# and possibly not as good as, Simon Brown's structurizr project.
#
# See https://github.com/mermaid-js/mermaid-cli#alternative-installations
# https://github.com/mermaid-js/mermaid-cli/releases/tag/10.1.0
mermaidImage = minlag/mermaid-cli:10.1.0

# Structurizr is Simon Brown's java-based tooling for creating
# and showing his own notion of c4 diagrams, using a domain-specific
# language (DSL) that he developed. The DSL is declarative. It
# lets one define components, link them to each other, embed them
# in each other, etc.
#
# Web app at https://github.com/structurizr/lite
# CLI at https://github.com/structurizr/cli
#
# Both tools want the DSL code in a file that by default is
# called "workspace.dsl". Wierd that the suffix is so generic,
# but that's what it is.
#
# One dsl file describes _any number of diagrams_ as "views"
# of models defined and reused in the file. A dsl can import other
# dsl files and may refer to theme data, icons, etc. in nearby files.
# Hence, structurizer has a notion of a "workspace" directory, home
# to the "workspace.dsl" file and whatever it refers to.
#
# This is analogous to a Go module - a directory containing
# one go.mod file and any number of other files and directories.
#
# So if you want to make a bunch of diagrams for some project,
# it probably makes sense to dedicate a directory to that purpose,
# and refer to images generated in that directory from some other
# place, e.g. the README.md for some git repo.
#
# The web app is lets one visualize and edit the dsl file, and
# and export images.
#
# Also it creates and leaves behind a ./.structurizr
# directory with more state of some kind - not sure if that's
# diagram specific or just app overhead.
#

# https://hub.docker.com/r/structurizr/lite/tags
# https://github.com/structurizr/lite/tags
strzLiteImage = structurizr/lite:3050

# https://hub.docker.com/r/structurizr/cli/tags
# https://github.com/structurizr/cli
strzCliImage = structurizr/cli:1.30.0

.PHONY: runStzrLite
runStzrLite:
	docker run -it --rm -p 8080:8080 \
		-v /home/jregan/myrepos/github.com/monopole/c4diagrams/c4_3dx:/usr/local/structurizr \
		$(strzLiteImage)

# This command will create N mermaid files, where N is the number
# of views defined in the "workspace" DSL file.  The mermaid file
# names come from the view names, and are prefixed by "structurizr-" (yuck).
structurizr-myDiagram.dot:
	docker run -it --rm \
		-v /home/jregan/myrepos/github.com/monopole/c4diagrams/c4_3dx:/usr/local/structurizr \
		$(strzCliImage) \
		export \
		--workspace /usr/local/structurizr \
		--output /usr/local/structurizr \
		--format dot

structurizr-myDiagram.mmd:
	docker run -it --rm \
		-v /home/jregan/myrepos/github.com/monopole/c4diagrams/c4_3dx:/usr/local/structurizr \
		$(strzCliImage) \
		export \
		--workspace /usr/local/structurizr \
		--output /usr/local/structurizr \
		--format mermaid

structurizr-myDiagram.xxx:
	docker run -it --rm \
		-v /home/jregan/myrepos/github.com/monopole/c4diagrams/c4_3dx:/usr/local/structurizr \
		$(strzCliImage) \
		export \
		--workspace /usr/local/structurizr \
		--output /usr/local/structurizr \
		--format plantuml

# Using mermaid to make an svg (not very good)
#myDiagram.svg: structurizr-myDiagram.mmd
#	docker run --rm -u `id -u`:`id -g` \
#		-v $$PWD/c4_3dx:/data \
#		$(mermaidImage) -i structurizr-myDiagram.mmd -o myDiagram.svg

# Using dot to make the svg
myDiagram.svg: structurizr-myDiagram.dot
	cd c4_3dx; dot -Tsvg structurizr-myDiagram.dot >myDiagram.svg

installGraphvix:
	sudo apt-get install graphviz

# https://github.com/pmorch/c4viz
.PHONY: runC4viz
runC4viz:
	docker run -it --rm -p 8080:8080 \
		-u $(id -u):$(id -g) \
		-v $$PWD:/sourceDir \
		-e SERVER_PORT=8080 \
		-e C4VIZ_SOURCE=myDiagram.dsl \
		-e C4VIZ_SOURCE_DIR=/sourceDir \
		pmorch/c4viz:latest

install:
	docker pull $(strzLiteImage)
	docker pull $(strzCliImage)
	docker pull $(mermaidImage)


# Make a markdown file that imports images from a markdown file that declares inline mermaid diagrams.
3dx.md:
	cd systems; echo $$PWD; \
	docker run --rm -u `id -u`:`id -g` -v $$PWD:/data \
		$(mermaidImage) -i 3dxRaw.md -o 3dx.md

.PHONY: venvPython
#: Create virtual environment for python.
venvPython:
	virtualenv venv -p python3

.PHONY: installPython
#: Install python libraries.
installPython: venvPython
	source ./venv/bin/activate && pip install -r requirements.txt
