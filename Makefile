# Markdown Vala Library Makefile

VALAC = valac
VALAFLAGS = --target-glib=2.50 --thread

# Dependencies
PACKAGES = gio-2.0 gee-0.8
GTK_PACKAGE = gtk+-3.0

# Source files
SRCS = src/markdown.vala \
       src/markdown-parser.vala \
       src/markdown-writer.vala \
       src/html-renderer.vala \
       src/gtk-css-renderer.vala

# Output
LIBNAME = libmarkdown
OUTPUT_DIR = build

# Compiler flags
CFLAGS = -Wall -O2

.PHONY: all clean lib examples test install

all: lib examples

lib:
	@mkdir -p $(OUTPUT_DIR)
	$(VALAC) $(VALAFLAGS) --library=$(LIBNAME) \
		--header=$(OUTPUT_DIR)/markdown.h \
		--vapi=$(OUTPUT_DIR)/markdown.vapi \
		-o $(OUTPUT_DIR)/$(LIBNAME).so \
		$(SRCS) \
		$(addprefix --pkg=,$(PACKAGES)) \
		-X -fPIC -X -shared \
		-X $(CFLAGS)

examples: lib
	@mkdir -p $(OUTPUT_DIR)
	# CLI example
	$(VALAC) $(VALAFLAGS) \
		-o $(OUTPUT_DIR)/markdown-cli \
		examples/markdown-cli.vala \
		$(SRCS) \
		$(addprefix --pkg=,$(PACKAGES))

	# GTK example (if GTK available)
	$(VALAC) $(VALAFLAGS) \
		-o $(OUTPUT_DIR)/markdown-editor \
		examples/markdown-editor.vala \
		$(SRCS) \
		$(addprefix --pkg=,$(PACKAGES)) \
		--pkg=$(GTK_PACKAGE) || echo "GTK not available, skipping editor"

test: lib
	@mkdir -p $(OUTPUT_DIR)
	$(VALAC) $(VALAFLAGS) \
		-o $(OUTPUT_DIR)/test-basic \
		tests/test-basic.vala \
		$(SRCS) \
		$(addprefix --pkg=,$(PACKAGES))
	$(OUTPUT_DIR)/test-basic

clean:
	rm -rf $(OUTPUT_DIR)
	rm -f *.c

install: lib
	install -d $(DESTDIR)/usr/lib
	install -d $(DESTDIR)/usr/include/markdown
	install -d $(DESTDIR)/usr/share/vala/vapi
	install -m 644 $(OUTPUT_DIR)/$(LIBNAME).so $(DESTDIR)/usr/lib/
	install -m 644 $(OUTPUT_DIR)/markdown.h $(DESTDIR)/usr/include/markdown/
	install -m 644 $(OUTPUT_DIR)/markdown.vapi $(DESTDIR)/usr/share/vala/vapi/

# Development targets
dev: all test

# Package source distribution
dist:
	tar -czf markdown-vala.tar.gz \
		src/*.vala \
		examples/*.vala \
		tests/*.vala \
		meson.build README.md Makefile

.PHONY: dev dist
