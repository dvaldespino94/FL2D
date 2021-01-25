//import fltk_d;

import fl2d;
import std.stdio;
import std.string;
import std.format;
import core.stdc.stdlib;
import std.file;
import std.algorithm.iteration;
import std.algorithm.searching;
import std.path;

int main(string[] fnames)
{
    fnames = fnames[1 .. $];
    if (fnames.length == 0)
    {
        writeln("No paths feeded!");
        return -1;
    }

    if (!fnames.all!(x => exists(x)))
    {
        writeln("Can't find some files");
        foreach (fname; fnames.filter!(x => !exists(x)))
        {
            writeln("\t-" ~ fname);
        }

        return -1;
    }

    foreach (fname; fnames)
    {
        assert(fname.extension == ".json");

        string outfname = fname.stripExtension ~ ".d";
        std.file.write(outfname, generate(readText(fname)));

        version (linux)
        {
            if (exists("/usr/bin/dfmt"))
            {
                core.stdc.stdlib.system(cast(const char*)("/usr/bin/dfmt --inplace \"%s\"".format(outfname)
                        .toStringz));
            }
        }
    }

    return 0;
}
