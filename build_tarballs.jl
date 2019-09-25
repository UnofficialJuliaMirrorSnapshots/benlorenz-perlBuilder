# Note that this script can accept some limited command-line arguments, run
# `julia build_tarballs.jl --help` to see a usage message.
using BinaryBuilder

name = "perl"
version = v"5.30.0"

# Collection of sources required to build perl
# with a few extra modules for polymake
sources = [
    "https://www.cpan.org/src/5.0/perl-$version.tar.gz" =>
    "851213c754d98ccff042caa40ba7a796b2cee88c5325f121be5cbb61bbf975f2",

    "https://cpan.metacpan.org/authors/id/I/IS/ISHIGAKI/JSON-4.01.tar.gz" =>
    "631593a939d4510e6ed76402556f38a34b20007237828670282e975712e0b1ed",

    "https://cpan.metacpan.org/authors/id/J/JO/JOSEPHW/XML-Writer-0.625.tar.gz" =>
    "e080522c6ce050397af482665f3965a93c5d16f5e81d93f6e2fe98084ed15fbe",

    "https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/XML-LibXML-2.0132.tar.gz" =>
    "721452e3103ca188f5968ab06d5ba29fe8e00e49f4767790882095050312d476",

    "https://cpan.metacpan.org/authors/id/S/SH/SHLOMIF/XML-LibXSLT-1.96.tar.gz" =>
    "2a5e374edaa2e9f9d26b432265bfea9b4bb7a94c9fbfef9047b298fce844d473",

    "https://cpan.metacpan.org/authors/id/J/JS/JSTOWE/TermReadKey-2.38.tar.gz" =>
    "5a645878dc570ac33661581fbb090ff24ebce17d43ea53fd22e105a856a47290",

    "https://cpan.metacpan.org/authors/id/H/HA/HAYASHI/Term-ReadLine-Gnu-1.36.tar.gz" =>
    "9a08f7a4013c9b865541c10dbba1210779eb9128b961250b746d26702bab6925",

    "https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-1.02.tar.gz" =>
    "4506c387043aa6a77b455f00f57409f3720aa7e553495ab2535263b4ed1ea12a",

    "https://cpan.metacpan.org/authors/id/P/PE/PERIGRIN/XML-NamespaceSupport-1.12.tar.gz" =>
    "47e995859f8dd0413aa3f22d350c4a62da652e854267aa0586ae544ae2bae5ef",

    "https://cpan.metacpan.org/authors/id/G/GR/GRANTM/XML-SAX-Base-1.09.tar.gz" =>
    "66cb355ba4ef47c10ca738bd35999723644386ac853abbeb5132841f5e8a2ad0",

    "https://cpan.metacpan.org/authors/id/M/MA/MANWAR/SVG-2.84.tar.gz" =>
    "ec3d6ddde7a46fa507eaa616b94d217296fdc0d8fbf88741367a9821206f28af",

    "./bundled"
]

# Bash recipe for building
script = raw"""
perldir=`ls -1d perl-*`
cd $WORKSPACE/srcdir/
for dir in *;
do
   [[ "$dir" == "perl-"* ]] && continue;
   [[ "$dir" == "patches" ]] && continue;
   sed -i '1s/^/$ENV{PERL_CORE}=0;/' $dir/Makefile.PL
   mv $dir $perldir/cpan/${dir%-*};
done

cd $perldir/
if [[ $target != x86_64-linux* ]] && [[ $target != i686-linux* ]]; then
   # build host miniperl
   src=`pwd`
   mkdir $src/host
   cd $src/host
   $src/Configure -des -Dusedevel -Dmksymlinks -Dosname=linux -Dcc=$CC_FOR_BUILD -Dld=$LD_FOR_BUILD -Dlibs=-lm
   make -j${nproc} miniperl
   make -j${nproc} generate_uudmap
   cp -p miniperl $prefix/bin/miniperl-for-build
   cd ..
   cp ../patches/config-$target.sh config.sh
   atomic_patch -p1 ../patches/cross-nolibchecks.patch
   ./Configure -K -S
else
   atomic_patch -p1 ../patches/cross-nolibchecks.patch
   ./Configure -des -Dcc="$CC" -Dprefix=$prefix -Duseshrplib -Dsysroot=/opt/$target/$target/sys-root -Dccflags="-I${prefix}/include -I${prefix}/include/libxml2" -Dldflags="-L${prefix}/lib -Wl,-rpath,${prefix}/lib" -Dlddlflags="-shared -L${prefix}/lib -Wl,-rpath,${prefix}/lib"
fi

make -j${nproc} depend
make -j${nproc}

make install

pushd $prefix/lib
ln -s perl5/*/*/CORE/libperl.${dlext} libperl.${dlext}
popd

if [[ $target == *linux* ]]; then
patchelf --set-rpath $(patchelf --print-rpath ${prefix}/bin/perl | sed -e "s#${prefix}#\$ORIGIN/..#g") ${prefix}/bin/perl
for lib in ${prefix}/lib/perl5/*/*/auto/XML/LibXML/LibXML.${dlext} \
           ${prefix}/lib/perl5/*/*/auto/XML/LibXSLT/LibXSLT.${dlext};
do
   patchelf --set-rpath $(patchelf --print-rpath ${lib} | sed -e "s#${prefix}/lib#\$ORIGIN/../../../../../..#g") ${lib};
done
fi


"""

# These are the platforms we will build for by default, unless further
# platforms are passed in on the command line
platforms = [
    Linux(:x86_64, libc=:glibc)
    Linux(:i686, libc=:glibc)
    MacOS(:x86_64)
]


# The products that we will ensure are always built
products(prefix) = [
    ExecutableProduct(prefix, "perl", :perl)
    LibraryProduct(prefix, "libperl", :libperl)
]

# Dependencies that must be installed before this package can be built
dependencies = [
    "https://github.com/bicycle1885/ZlibBuilder/releases/download/v1.0.4/build_Zlib.v1.2.11.jl",
    "https://github.com/JuliaPackaging/Yggdrasil/releases/download/XML2-v2.9.9+0/build_XML2.v2.9.9.jl",
    "https://github.com/benlorenz/XSLTBuilder/releases/download/v1.1.33/build_XSLTBuilder.v1.1.33.jl",
    "https://github.com/benlorenz/readlineBuilder/releases/download/v8.0/build_readline.v8.0.0.jl",
    "https://github.com/benlorenz/ncursesBuilder/releases/download/v6.1/build_ncurses.v6.1.0.jl"
]

# Build the tarballs, and possibly a `build.jl` as well.
build_tarballs(ARGS, name, version, sources, script, platforms, products, dependencies)

