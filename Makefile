# General idea
#
#    * Maintain diagrams as human-readable, human-editable textual
#      instructions stored in github.
#
#    * Generate images (png's, svg's) from these instructions at will,
#      via simple commands that can be part of a Makefile or CI/CD.
#
#    * Optional: Use graphical tool to do layout (since auto-layout usually looks bad).
#
#    * Include these images in markdown.
#
#      The basic markdown syntax for image import is
#         ![my fancy diagram](./some/diagram.svg "My Fancy Diagram")
#
#      To get a desired size, use a raw HTML image tag, e.g.
#         <img src="./some/diagram.svg" alt="my fancy diagram" title="My Fancy Diagram" width="150"/>
#
# The field of generated systems drawing is dysfunctional right now.

# Mermaid ------------------------------
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

# C4-PlantUML ---------------------------------
#
# A set of macros, types, themes, etc. that can be consumed by plantuml
# to make better looking c4 diagrams (with notions of "person", "system", etc.)
# This data stands apart from, but _adds value_ to, the plantuml project.
# For whatever reason, the creators maintain this in their own repo rather
# than open a PR at https://github.com/plantuml/plantuml and upstream it.
# See https://github.com/plantuml-stdlib/C4-PlantUML/releases
# This stuff isn't containerized, but can be used from the plantuml container.
C4-PlantUML-2.5.0:
	wget -q -O - https://github.com/plantuml-stdlib/C4-PlantUML/archive/refs/tags/v2.5.0.tar.gz |\
 	gunzip | tar xf -

# plantuml ------------------------------------------
#
# plantuml is a venerable java project to create diagrams from text.
# It doesn't model things or have any rules about how one would
# create a "coherent" c4 diagram.
#
# https://github.com/plantuml/plantuml
# https://hub.docker.com/r/plantuml/plantuml/tags
# This image include the plantuml java jars and a JVM and graphviz (the dot program).
plantUmlImage = plantuml/plantuml:1.2023.6

# Structurizr ---------------------------------------------
#
# Structurizr is Simon Brown's java-based tooling for creating
# and showing his own notion of c4 diagrams, using a domain-specific
# language (DSL) that he developed. The DSL is declarative. It
# lets one define components, link them to each other, embed them
# in each other, etc.
#
# This is the closed-source structurizr web app.
# Can export images, but only interactively (hit buttons, download, copy out of Download folder).
# https://hub.docker.com/r/structurizr/lite/tags
# https://github.com/structurizr/lite/tags
strzLiteImage = structurizr/lite:3050
#
# This is the open source structurizr CLI -- doesn't export SVG directly!
# Needs to use plantuml, or mermaid, to render.
# https://hub.docker.com/r/structurizr/cli/tags
# https://github.com/structurizr/cli
strzCliImage = structurizr/cli:1.30.0
#
# Both the "lite" server and the "cli" want the DSL code in a
# file that by default is called "workspace.dsl". Odd that such
# a generic name was chosen, as opposed to say Structurizrfile
# (like Dockerfile, Makefile, etc.), but that's what it is.
#
# One dsl file describes _any number of diagrams_ as "views"
# of models defined and reused in the file. A dsl can import other
# dsl files and may refer to theme data, icons, etc. in nearby files.
# Hence, structurizer has a notion of a "workspace" directory, home
# to the "workspace.dsl" file and whatever it refers to.
#
# This directory is analogous to a Go module - a directory containing
# one go.mod file and any number of other files and directories.
#
# If you want to make a bunch of diagrams for some project, dedicate
# a directory to that purpose, and refer to images generated in that
# directory from some other place, e.g. the README.md for some git repo.
#
# The killer feature of structurizr (over mermaid and plantUML)
# is that the dsl lets you define _objects_ (people, programs, DBs,
# servers, etc.) and any number of views (diagrams) that re-use
# these objects, with rules about how they can be combined (or
# not combined). The other tools are 1:1 diagram:file, and have
# no rules.  plantuml has a dumb include feature lacking
# composition rules and semantics.

dashboard, 3espace,  - doesn't know
tomee
database
client

553 new client, new tag.


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

structurizr-myDiagram.puml:
	docker run -it --rm \
		-v /home/jregan/myrepos/github.com/monopole/c4diagrams/c4_3dx:/usr/local/structurizr \
		$(strzCliImage) \
		export \
		--workspace /usr/local/structurizr \
		--output /usr/local/structurizr \
		--format plantuml

# Using mermaid to make an svg (not very good)
myMermaidDiagram.svg: structurizr-myDiagram.mmd
	docker run --rm -u `id -u`:`id -g` \
		-v $$PWD/c4_3dx:/data \
		$(mermaidImage) -i structurizr-myDiagram.mmd -o myMermaidDiagram.svg

# Using dot to make the svg
myDotDiagram.svg: structurizr-myDiagram.dot
	cd c4_3dx; dot -Tsvg structurizr-myDiagram.dot >myDotDiagram.svg



# An example of using plantuml with the c4-plantuml enhancements.
examples/bigbank.svg: examples/bigbank_context.puml
	docker run -it --rm \
		-v $$PWD/examples:/data \
		-v $$PWD/C4-PlantUML-2.5.0:/C4-PlantUML \
		$(plantUmlImage) -DRELATIVE_INCLUDE="../C4-PlantUML" bigbank_context.puml -tsvg

installGraphviz:
	sudo apt-get install graphviz

installJava:
	sudo apt install openjdk-19-jre-headless

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
