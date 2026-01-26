# Libsitra Sources
libsitra_sources = [
    'categories.vala',
    'licenses.vala',
    'font.vala',
    'fonts.vala',
    'library.vala'
]

# Libsitra Dependencies
libsitra_deps = [
    dependency('glib-2.0'),
    dependency('gio-2.0'),
    dependency('gobject-2.0'),
    dependency('gee-0.8'),
    dependency('libsoup-3.0'),
    dependency('json-glib-1.0'),
]

# Install JSON data files
install_data(
    'assets/fonts.json',
    'assets/google-fonts.json',
    install_dir: get_option('datadir') / 'libsitra'
)

# Build Static Library
libsitra_lib = shared_library('sitra',
    libsitra_sources,
    dependencies: libsitra_deps,
    version: meson.project_version(),
    soversion: '0',
    install: true,
    vala_vapi: 'libsitra-0.1.vapi',
    vala_header: 'libsitra.h',
    vala_gir: 'Libsitra-0.1.gir',
    c_args: [
        '-Wno-unused-parameter',
        '-Wno-unused-variable',
        '-Wno-unused-but-set-variable',
        '-Wno-discarded-qualifiers',
    ],
)

# Declare dependency for use as subproject
libsitra_dep = declare_dependency(
    link_with: libsitra_lib,
    dependencies: libsitra_deps,
    include_directories: include_directories('.'),
)