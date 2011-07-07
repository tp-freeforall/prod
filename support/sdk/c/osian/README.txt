This directory contains include files relevant to OSIAN but not restricted
to TinyOS.  The <osian/*.h> files should be safe to include in C, C++ and
TinyOS code.

Note that it is this directory, not the osian subdirectory, that should be
specified when listing include paths.  Include directives should incorporate
the osian path to deconflict with other files of similar names.

#include <osian/version.h>

