project('markdown-vala', 'vala', 'c',
  version: '1.0.0',
  meson_version: '>= 0.50.0',
  default_options: ['warning_level=2']
)

# Dependencies
gio_dep = dependency('gio-2.0', required: true)
gee_dep = dependency('gee-0.8', required: true)
gtk_dep = dependency('gtk4', required: false)

# Sources
markdown_sources = files(
  'src/markdown.vala',
  'src/markdown-parser.vala',
  'src/markdown-writer.vala',
  'src/html-renderer.vala',
  'src/pango-renderer.vala'
)

# Library dependencies
markdown_deps = [gio_dep, gee_dep]

if gtk_dep.found()
  markdown_deps += [gtk_dep]
endif

# Build shared library
markdown_lib = shared_library('markdown',
  markdown_sources,
  dependencies: markdown_deps,
  install: true,
  vala_args: ['--target-glib=2.50'],
)

markdown_dep = declare_dependency(
    link_with: markdown_lib,
    dependencies: markdown_deps,
    include_directories: [include_directories('.')]
)

# Example: CLI tool
executable('markdown-cli',
  'examples/markdown-cli.vala',
  dependencies: [gio_dep, gee_dep, markdown_dep],
  link_with: markdown_lib,
  install: false,
)

# Example: GTK Editor (if GTK available)
if gtk_dep.found()
  executable('markdown-editor',
    'examples/markdown-editor.vala',
    dependencies: [gio_dep, gee_dep, gtk_dep, markdown_dep],
    link_with: markdown_lib,
    install: false,
  )
endif

# Tests
test_exe = executable('markdown-tests',
  'tests/test-basic.vala',
  dependencies: [gio_dep, gee_dep, markdown_dep],
  link_with: markdown_lib,
)

test('markdown-basic', test_exe)

# pkg-config file
pkg = import('pkgconfig')
pkg.generate(markdown_lib,
  subdirs: 'markdown',
  name: 'markdown-vala',
  description: 'Markdown processing library for Vala',
  version: meson.project_version(),
)
