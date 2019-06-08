#!/usr/bin/make

CC = gcc-8
CFLAGS := $(CFLAGS) -Wall -Os -I . -I /usr/include/python3.6m -g
CYTHON := cython3
CYTHON_FLAGS := --embed --directive language_level=3
OUTPUT_FILE := ./mangen
MAKEFLAGS := $(MAKEFLAGS) s
CYTHON_OUTPUT := ./mangen.py.c
EXECUTABLE_INSTALL_LOCATION := /usr/bin/mangen

.PHONY: all clean

all: $(OUTPUT_FILE);

$(OUTPUT_FILE): $(CYTHON_OUTPUT)
	$(CC) $(CFLAGS) $(CYTHON_OUTPUT) -lpython3.6m -o $(OUTPUT_FILE)

$(CYTHON_OUTPUT): ./mangen.pyx
	$(CYTHON) $(CYTHON_FLAGS) ./mangen.pyx -o $(CYTHON_OUTPUT)

install: $(OUTPUT_FILE)
	sudo install $(OUTPUT_FILE) $(EXECUTABLE_INSTALL_LOCATION)

./mangen.pyx:;

clean:
	-@$(RM) $(CYTHON_OUTPUT)	2>/dev/null	|| true
	-@$(RM) $(OUTPUT_FILE)		2>/dev/null	|| true
