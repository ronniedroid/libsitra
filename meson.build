project ('libsitra', ['c', 'vala'],
    version: '0.1.0', # Define ONLY here
    meson_version: '>= 1.0.0',
    default_options: ['warning_level=2', 'werror=false'],
)

valac = meson.get_compiler ('vala')
srcdir = meson.project_source_root () / 'src'

# Unify version for C code (config.h)
config_h = configuration_data ()
config_h.set_quoted ('PACKAGE_VERSION', meson.project_version ()) # Uses 0.1.0
config_h.set_quoted ('LOCALEDIR', get_option ('prefix') / get_option ('localedir'))
configure_file (output: 'config.h', configuration: config_h)

config_inc = include_directories ('.')

# Move logic into src
subdir ('src')

# Pkg-config unification
pkg = import ('pkgconfig')
pkg.generate (
    libsitra_lib,                # Pass the library object directly
    subdirs: 'libsitra',
    version: meson.project_version (),
    name: 'libsitra',
    filebase: 'libsitra-0.1',    # Keep the API version (0.1) in the filename
    description: 'Shared library for Sitra application',
    requires: ['glib-2.0', 'gio-2.0', 'gee-0.8', 'libsoup-3.0', 'json-glib-1.0']
)