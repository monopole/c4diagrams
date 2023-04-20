
# mermaid is a huge pile of javascript that converts textual descriptions
# of diagrams into .svg files.
#
# It can also convert a specially annotated markdown file into a new markdown file
# with images replacing textually embedded diagram descriptions.
# @jregan tried this latter usage style and found it unwieldy and wierd as soon as
# the diagrams got to be more complex than just two or three boxes.
#
# It's easier to write a markdown doc with no attempts to embed diagram text,
# and instead use image tags to import diagram images generated via some
# other workflow.
#
#   To import an image into markdown use
#     ![my fancy diagram](./some/diagram.svg "My Fancy Diagram")
#   To get a desired size, use bare HTML image tag, e.g.
#    <img src="./some/diagram.svg" alt="my fancy diagram" title="My Fancy Diagram" width="150"/>
# A Makefile is a good way to arrange for generation of the .svg files.
#
# With respect to C4 diagrams, mermaid has its own notation, and it's
# not the same as, and possibly not as good as, Simon Brown's structurizr project.
#
# See https://github.com/mermaid-js/mermaid-cli#alternative-installations
# https://github.com/mermaid-js/mermaid-cli/releases/tag/10.1.0
mermaidImage = minlag/mermaid-cli:10.1.0

# Structurizr is Simon Brown's java-based tooling for creating and showing his
# own notion of c4 diagrams, using a domain-specific language (DSL) that
# he developed. The DSL is declarative. It lets one define components,
# link them to each other, embed them in each other, etc.
# There's a web app at https://github.com/structurizr/lite
# and a CLI at https://github.com/structurizr/cli
#
# Both tools want the DSL code in a file that by default is called "workspace.dsl".
# It's a bit naive to use such a generic extension suffix, but that's what he did.
# A DSL file describes one diagram (albeit possibly importing other dsl files).
# It sits in a directory alongside any supplemental files, e.g. theme data, icons, etc.
#
# To have more than one diagram in a directory, one must call them something
# other than "workspace.dsl", and pass that name to the tooling (at the time of writing,
# this is done via the STRUCTURIZR_WORKSPACE_FILENAME shell var).
#
# The web app is lets one visualize and edit a single DSL file.  Not the best design.
# Also it creates and leaves behind a ./.structurizr dorectory with more state
# of some kind - not sure if that's diagram specific or just app overhead.
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
		-v $$PWD:/usr/local/structurizr \
		-e STRUCTURIZR_WORKSPACE_FILENAME=myDiagram \
		$(strzLiteImage)


# This command will create N mermaid files, where N is the number
# of views defined in the DSL.  Thefile names come from
# the view names, and are prefixed by "structurizr-" (dumb).
structurizr-myDiagram.mmd:
	docker run -it --rm \
		-v $$PWD:/usr/local/structurizr \
		$(strzCliImage) \
		export \
		--workspace /usr/local/structurizr/myDiagram.dsl \
		--output /usr/local/structurizr \
		--format mermaid

myDiagram.svg: structurizr-myDiagram.mmd
	docker run --rm -u `id -u`:`id -g` \
		-v $$PWD:/data \
		$(mermaidImage) -i structurizr-myDiagram.mmd -o myDiagram.svg

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
