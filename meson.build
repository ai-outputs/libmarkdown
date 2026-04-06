# Vala Markdown Module - Meson 构建配置
# 
# 使用方法：
#   meson setup build
#   cd build
#   ninja
#   ninja test
#   ninja install

project(
    'vala-markdown',
    ['vala', 'c'],
    version: '1.1.0',
    meson_version: '>= 0.50.0',
    default_options: [
        'warning_level=2',
        'werror=false',
    ]
)

# 依赖项
glib_dep = dependency('glib-2.0', version: '>= 2.50')
gobject_dep = dependency('gobject-2.0', version: '>= 2.50')
gio_dep = dependency('gio-2.0', version: '>= 2.50')
gee_dep = dependency('gee-0.8', version: '>= 0.20')

# 源文件（按依赖顺序）
sources = files(
    'yaml-types.vala',
    'yaml-reader.vala',
    'markdown-types.vala',
    'markdown-nodes.vala',
    'markdown-reader.vala',
    'markdown-writer.vala',
    'markdown.vala'
)

# 编译库
markdown_lib = shared_library(
    'markdown',
    sources,
    dependencies: [glib_dep, gobject_dep, gio_dep, gee_dep],
    install: true,
)

# 编译主示例程序
example_exe = executable(
    'markdown-example',
    sources + files('example.vala'),
    dependencies: [glib_dep, gobject_dep, gio_dep, gee_dep],
    install: false
)

# 编译 YAML 示例程序
yaml_example_exe = executable(
    'yaml-example',
    sources + files('example-yaml.vala'),
    dependencies: [glib_dep, gobject_dep, gio_dep, gee_dep],
    install: false
)

# 测试程序
test_exe = executable(
    'markdown-test',
    sources + files('test.vala'),
    dependencies: [glib_dep, gobject_dep, gio_dep, gee_dep],
    install: false
)

# 定义测试
test('markdown-tests', test_exe)

# Pkg-config 文件
pkg = import('pkgconfig')
pkg.generate(markdown_lib,
    name: 'markdown',
    description: 'Vala Markdown parsing and rendering library with YAML support',
    version: meson.project_version()
)

# 总结
summary({
    'Version': meson.project_version(),
    'Prefix': get_option('prefix'),
    'Library': markdown_lib.name(),
    'Features': 'YAML Front Matter, GFM Extensions',
}, section: 'Configuration')
