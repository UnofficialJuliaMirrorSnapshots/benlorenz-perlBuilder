# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "perl"
version = v"5.28.2"

# Collection of sources required to build perl
# with a few extra modules for polymake
sources = [
    "https://www.cpan.org/src/5.0/perl-$version.tar.gz" =>
    "aa95456dddb3eb1cc5475fed4e08f91876bea71fb636fba6399054dfbabed6c7",

    "https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/JSON-2.97001.tar.gz" =>
    "e277d9385633574923f48c297e1b8acad3170c69fa590e31fa466040fc6f8f5a",

    "https://cpan.metacpan.org/authors/id/J/JO/JOSEPHW/XML-Writer-0.625.tar.gz" =>
    "e080522c6ce050397af482665f3965a93c5d16f5e81d93f6e2fe98084ed15fbe",

    "https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/XML-LibXML-2.0132.tar.gz" =>
    "721452e3103ca188f5968ab06d5ba29fe8e00e49f4767790882095050312d476",

    "https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/XML-LibXSLT-1.96.tar.gz" =>
    "2a5e374edaa2e9f9d26b432265bfea9b4bb7a94c9fbfef9047b298fce844d473",

    "https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.37.tar.gz" =>
    "4a9383cf2e0e0194668fe2bd546e894ffad41d556b41d2f2f577c8db682db241",

    "https://cpan.metacpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.35.tar.gz" =>
    "575d32d4ab67cd656f314e8d0ee3d45d2491078f3b2421e520c4273e92eb9125",

    "https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-1.00.tar.gz" =>
    "45ea6564ef8692155d57b2de0862b6442d3c7e29f4a9bc9ede5d7ecdc74c2ae3",

    "https://cpan.metacpan.org/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz" =>
    "47e995859f8dd0413aa3f22d350c4a62da652e854267aa0586ae544ae2bae5ef",

    "https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz" =>
    "66cb355ba4ef47c10ca738bd35999723644386ac853abbeb5132841f5e8a2ad0",

    "https://cpan.metacpan.org/authors/id/M/MA/MANWAR/SVG-2.84.tar.gz" =>
    "ec3d6ddde7a46fa507eaa616b94d217296fdc0d8fbf88741367a9821206f28af",

]

# Bash recipe for building across all platforms
# currently missing:
#   Term-ReadLine-Gnu-1.35
#   - not needed for callable
script = raw"""
cd $WORKSPACE/srcdir/perl-5.28.2/
./Configure -des -Dcc=gcc -Dprefix=$prefix -Duseshrplib -Darchname=$target -Dsysroot=/opt/$target/$target/sys-root
make -j${nproc} install

for perlmoddir in JSON-2.97001 XML-NamespaceSupport-1.12 XML-SAX-Base-1.09 \
                  XML-SAX-1.00 XML-Writer-0.625 XML-LibXML-2.0132 TermReadKey-2.37 \
                  SVG-2.84;
do
   cd $WORKSPACE/srcdir/$perlmoddir;
   ${prefix}/bin/perl Makefile.PL;
   make install;
done

cd $WORKSPACE/srcdir/XML-LibXSLT-1.96
${prefix}/bin/perl Makefile.PL LIBS="-L${prefix}/lib -lxslt -lexslt -lxml2 -lm -lz" INC="-I${prefix}/include -I${prefix}/include/libxml2"
make install

patchelf --set-rpath $(patchelf --print-rpath ${prefix}/bin/perl | sed -e "s#${prefix}#\$ORIGIN/..#g") ${prefix}/bin/perl
for lib in ${prefix}/lib/perl5/site_perl/*/*/auto/XML/LibXML/LibXML.so \
           ${prefix}/lib/perl5/site_perl/*/*/auto/XML/LibXSLT/LibXSLT.so;
do
   patchelf --set-rpath $(patchelf --print-rpath ${lib} | sed -e "s#${prefix}/lib#\$ORIGIN/../../../../../../..#g") ${lib};
done

"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
    Linux(:i686, libc=:glibc)
]
#TODO: platforms = supported_platforms()


# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "perl", :perl)
]
# TODO: add with correct path?
#    LibraryProduct(prefix, "libperl", :libperl),

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/bicycle1885/XML2Builder/releases/download/v1.0.2/build_XML2Builder.v2.9.9.jl",
    "https://github.com/benlorenz/XSLTBuilder/releases/download/v1.1.33/build_XSLTBuilder.v1.1.33.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

