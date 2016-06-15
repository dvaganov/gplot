PROG_NAME = gplot

SOURCE_DIR = src
DATA_DIR = $(SOURCE_DIR)/data
RESOURCE_NAME = $(DATA_DIR)/$(PROG_NAME).gresource.xml

SRC = \
$(shell find $(SOURCE_DIR)/ -type f -name '*.vala') \
$(DATA_DIR)/$(PROG_NAME).c

all:
	make $(PROG_NAME)
	make clean

$(DATA_DIR)/$(PROG_NAME).c: $(RESOURCE_NAME)
	cd $(DATA_DIR)/ && \
	glib-compile-resources --generate-source $(PROG_NAME).gresource.xml

clean:
	find ./ -type f -name *.c -delete

$(PROG_NAME): $(SRC)
	valac \
	--cc=clang \
	--target-glib=2.38 \
	--gresources $(RESOURCE_NAME) \
	--pkg gtk+-3.0 $(SRC) \
	-o $(PROG_NAME)
