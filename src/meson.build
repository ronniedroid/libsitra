# Libsitra Sources
libsitra_sources = [
    'font.vala',
    'fonts.vala',
    'library.vala'
]

# Libsitra Dependencies
libsitra_deps = [
    dependency ('glib-2.0'),
    dependency ('gio-2.0'),
    dependency ('gobject-2.0'),
    dependency ('gee-0.8'),
    dependency ('libsoup-3.0'),
    dependency ('json-glib-1.0'),
]

gnome = import ('gnome')

libsitra_resources = gnome.compile_resources ('libsitra-resources',
    'io.github.sitraorg.libsitra.gresource.xml',
    source_dir: '.',
    c_name: 'libsitra'
)

# Build Shared Library
libsitra_lib = shared_library ('sitra',
    libsitra_sources + libsitra_resources,
    dependencies: libsitra_deps,
    version: meson.project_version (),
    soversion: '0',
    install: true,
    install_dir: [true, true, true, true],
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
libsitra_dep = declare_dependency (
    link_with: libsitra_lib,
    dependencies: libsitra_deps,
    include_directories: include_directories ('.'),
)