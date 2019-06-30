#!/usr/bin/make

CC = gcc-8
CFLAGS := $(CFLAGS) -fPIC $(shell python3-config --cflags) # -Wall -Os -I . -I /usr/include/python3.6m -g
CLIBS := $(CLIBS) $(shell python3-config --libs)
CYTHON := cython3
CYTHON_FLAGS := --embed --directive language_level=3
OUTPUT_FILE := ./mangen
# MAKEFLAGS := $(MAKEFLAGS) s
CYTHON_OUTPUT := ./mangen.py.c
EXECUTABLE_INSTALL_LOCATION := /usr/bin/mangen
MAN_FILE := ./mangen.1.gz
MAN_INSTALL_LOCATION := /usr/share/man/man1/mangen.1.gz
SPEC := ./mangen-spec.json

.PHONY: all clean install

all: $(OUTPUT_FILE);

$(OUTPUT_FILE): $(CYTHON_OUTPUT)
	$(CC) $(CFLAGS) $(CYTHON_OUTPUT) -lpython3.6m -o $(OUTPUT_FILE) $(CLIBS)

$(CYTHON_OUTPUT): ./mangen.pyx
	$(CYTHON) $(CYTHON_FLAGS) ./mangen.pyx -o $(CYTHON_OUTPUT)

install: $(EXECUTABLE_INSTALL_LOCATION) $(MAN_INSTALL_LOCATION)

$(MAN_INSTALL_LOCATION): $(MAN_FILE)
	sudo install $< $@

$(EXECUTABLE_INSTALL_LOCATION): $(OUTPUT_FILE)
	sudo install $< $@

$(MAN_FILE): $(SPEC) $(OUTPUT_FILE)
	(./mangen | gzip) < $< > $@

./mangen.pyx:;

clean:
	-@$(RM) $(CYTHON_OUTPUT)	2>/dev/null	|| true
	-@$(RM) $(OUTPUT_FILE)		2>/dev/null	|| true
	-@$(RM) $(MAN_FILE)		2>/dev/null	|| true
