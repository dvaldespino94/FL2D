# FL2D (Deprecated)
## D FLTK Code generator
### This is just a code generator that consumes _.json_ interface definitions generated by my modified __fluid__ (wich generates a .json copy of the UI)

There are 2 ways of using this:
- As a library:
    + You can generate the code in compile time and use it in your projects.
    + You can generate the code for later use.
- Standalone:
    + You can feed the .json files and it generates the .d code files

## Why?
- I love FLTK, but it's all C/C++, I don't see any FLTK Wrapper for D around, so I made one. **BUT**:
- Fluid generates C++ code, so I first tried to build SWIG wrappers arround then, but that was too tedious, so I slightly modified my __fluid__ app to dump a .json representation of my UI, and then created this project to generate the D code.

## Status
### This is based on fluid-generated files
- This means I only plan to support that input, wich is very concise, as I'm mantaining THE fluid version wich generates those .json files.
- Currently I only use a few widgets from FLTK, wich are the one wrapped in my FLTK Wrapper library but I'm planning to port all of them, (is quite easy, but I have no time).
- C/C++ decls in fluid's hierarchy are simply copied to the output
- Currently only a few properties are mapped:
    + Colors, boxes, label(and label properties), align, xywh, and others

## I changed my mind, this project is deprecated now:
Last night I wrote a .fl parser, so this is not needed anymore. The parser is not completely finished(I finished coding it like ~2am yesterday), but already has more features than this project, so...
