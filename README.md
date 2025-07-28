# About

An exploration of the possibilities to link ELF format in various ways.
Notably, explore following possibilities:

- Is it possible to embed a static library into a dynamic library ? (Yes)
- Is it possible to create a static library from a dynamic library ? (Not really)
- Is it possible to create a static library from a dynamic library ? (Yes)
- Is it possible to link an executable against both static and dynamic libraries ? (Yes)
- Is it possible to link an executable statically using gcc ? (Yes)
- What is the impact of various linkers ? (TODO)
- Bonus: building with `zig`

# Ref

- [1] https://www.lurklurk.org/linkers/linkers.html
  An excellent introduction to link procedures and conventions
- [2] https://gavinhoward.com/2021/10/static-linking-considered-harmful-considered-harmful/
  A deep dive into implication of static and dynamic linking. The article
  notably points out that dynamic linking is not always the answer (which seems
  to be often ignore in the Linux ecosystem)
- [3] https://stackoverflow.com/questions/65575673/is-it-possible-to-compile-a-c-program-with-both-static-and-dynamic-libraries
  On the `gcc` command to link against both static and dynamic libraries


# [build-1]() Build an executable which link against both static and dynamic objects

Dependency graph and goals

```
cat <<EOF
main
├─libstatic-2.a
└─libdynamic.so
  └─libstatic.a
EOF
```

- The first goal is to have `libstatic.a` statically linked against
  `libdynamic.so` so that `libdynamic.so` is a static shared library.
- The second goal is to have `main` which is both linked statically against
  `libstatic-2.a` and dynamically linked against `libdynamic.so`, to demonstrate
  that it is possible to combine static and dynamic linkage modes. It is also
  important to show that `libstatic.a` is not needed to link `main` against
  `libdynamic.so`, as `libdynamic.so` has been statically linked against
  `libstatic.a`

Create build directory

```
[ -d "build-1" ] && rm -r build-1
mkdir build-1
```

Build static archives (ie. static libraries)

```
gcc src/static.c -c -g -Wall -Wextra -O0 -static -o build-1/static.o
ar r build-1/libstatic.a build-1/static.o 2>/dev/null
```

```
gcc src/static-2.c -c -g -Wall -Wextra -O0 -static -o build-1/static-2.o
ar r build-1/libstatic-2.a build-1/static-2.o 2>/dev/null
```

`libstatic.a` is required by the dynamic library `libdynamic.so`, while the
second `libstatic-2.a` is required by `main`.

Build dynamic lib depending on the static archive

```
gcc \
    src/dynamic.c \
    -shared \
    -g \
    -fPIC \
    -Wall \
    -Wextra \
    -O0 \
    -o build-1/libdynamic.so \
    -L./build-1 \
    -Wl,-Bstatic \
    -lstatic \
    -Wl,-Bdynamic
```

Note the use of `-Wl,-Bstatic` to impose search of static libraries only.
`-Wl,-Bdynamic` falls back to the "dynamic, else static (if dynamic not found)". If `-Wl,-Bstatic`
is used, it is **mandatory that the last `-Wl,-B<some>` be `-Wl,-Bdynamic`.
Otherwise, linkage with `libc` fails.

Build main

```
gcc -g -Wall -Wextra -O0 \
    -o build-1/main \
    src/main.c \
    -L./build-1 \
    -Wl,-Bdynamic -ldynamic \
    -Wl,-Bstatic -lstatic-2 \
    -Wl,-Bdynamic
```

# [build-2]() Build using a dynamic library which is obtained from a static library

Dependency graph and goals

```
cat <<EOF
main
├─libstatic-2.a
└─libdynamic.so
  └─libstatic.so ← obtained from 'libstatic.a'
EOF
```

This is the same as `build-1`, but it demonstrates that it is possible to build
a shared library from a static one. Here, the dynamic library `libstatic.so` is
built from static library `libstatic.a`.

This section contains less explanation that `build-1`, as most of the
commands are identical. Explanations mainly emphasize differences, compared to
`build-1`.

Create the build directory

```
[ -d "build-2" ] && rm -r build-2
mkdir build-2
```

Build static archives (i.e. static libraries)

```
gcc src/static.c -c -g -Wall -Wextra -O0 -static -o build-2/static.o
gcc src/static-2.c -c -g -Wall -Wextra -O0 -static -o build-2/static-2.o

ar r build-2/libstatic.a build-2/static.o 2>/dev/null
ar r build-2/libstatic-2.a build-2/static-2.o 2>/dev/null
```

Transform the static library `libstatic.a` into a dynamic library:

The `-Wl,--whole-archive` option allows to create the dynamic library
directly from the static archive, **without any need for an intermediate binding
file**.

```
gcc -shared -fPIC -o build-2/libstatic.so -Wl,--whole-archive build-2/libstatic.a -Wl,--no-whole-archive
```

Build dynamic library depending on the dynamic version of the initial static library

```
gcc \
    src/dynamic.c \
    -shared \
    -static-libgcc \
    -g \
    -fPIC \
    -Wall \
    -Wextra \
    -O0 \
    -o build-2/libdynamic.so \
    -L./build-2/ \
    -Wl,-Bdynamic \
    -lstatic \
    -Wl,-Bdynamic
```

Build the executable

```
gcc -g -Wall -Wextra -O0 \
    -o build-2/main \
    src/main.c \
    -L./build-2/ \
    -Wl,-Bdynamic -ldynamic -lstatic \
    -Wl,-Bstatic -lstatic-2 \
    -Wl,-Bdynamic
```

# [build-3]() Build a fully static executable (GCC specific)

Dependency graph and goals

```
cat <<EOF
main
├─libstatic-2.a
└─libdynamic.a
  └─libstatic.a
EOF
```

This section demonstrates that it is possible to build a fully static
executable with gcc.

This section contains less explanation than `build-1`, as most of the
commands are the same. Explanations mainly emphasize differences compared to
`build-1`.

Create the build directory

```
[ -d "build-3" ] && rm -r build-3
mkdir build-3
```

Build static archives

**Even `dynamic.c` is built as a static library** here, to allow full static
linkage.

```
gcc src/static.c -c -g -Wall -Wextra -O0 -static -o build-3/static.o
gcc src/static-2.c -c -g -Wall -Wextra -O0 -static -o build-3/static-2.o
gcc src/dynamic.c -c -g -Wall -Wextra -O0 -static -o build-3/dynamic.o

ar r build-3/libstatic.a build-3/static.o 2>/dev/null
ar r build-3/libstatic-2.a build-3/static-2.o 2>/dev/null
ar r build-3/libdynamic.a build-3/dynamic.o 2>/dev/null
```

Build the executable statically

```
gcc -g -Wall -Wextra -O0 \
    -o build-3/main \
    src/main.c \
    -static -static-libgcc \
    -L./build-3/ \
    -Wl,-Bstatic -ldynamic -lstatic -lstatic-2
```

# [build-failure]() A failed attempt to link statically from a dynamically linked object

This section shows that it is not trivial to statically link a dynamic library
by splitting its symbols into object files. It does not work due to missing
linkage information in `libdynamic-symbols.o`, preventing from linking against
the latter. Linking is a destructive process.

```
[ -d "build-failure" ] && rm -r "build-failure"
mkdir "build-failure"

gcc src/static.c -c -g -Wall -Wextra -O0 -static -o build-failure/static.o
gcc src/static-2.c -c -g -Wall -Wextra -O0 -static -o build-failure/static-2.o

ar r build-failure/libstatic.a build-failure/static.o 2>/dev/null
ar r build-failure/libstatic-2.a build-failure/static-2.o 2>/dev/null

gcc src/dynamic.c \
    -shared \
    -static-libgcc \
    -g \
    -fPIC \
    -Wall \
    -Wextra \
    -O0 \
    -o build-failure/libdynamic.so \
    -L./build-failure/ \
    -Wl,-Bdynamic \
    -lstatic \
    -Wl,-Bdynamic
```
Extract symbols from a `.so` library:

```
objcopy --extract-symbol build-failure/libdynamic.so build-failure/libdynamic-symbols.o
```

Build a static library from the extracted symbols:

```
ar r build-failure/libdynamic.a build-failure/libdynamic-symbols.o
```

Link with object file of extracted symbols of dynamic library

**This command does not work** (probably because of missing linker directive
inside object files):

```
gcc src/main.c -c -g -Wall -Wextra -O0 -o build-failure/main.o
gcc -o build-failure/main \
    build-failure/main.o \
    build-failure/static.o \
    build-failure/static-2.o \
    build-failure/libdynamic-symbols.o
```

# [build-zig]() Build an executable using the Zig build system

Use zig toolchain to build the executable

```
{
    zig_tool="$(which "zig")" && [ -x "$zig_tool" ]
} || {
    echo "Fatal error: Zig not found on your system. Abort." >&2
    exit 1
}
zig build -Dtarget=x86_64-linux-musl
```

Due to the `-Dtarget=x86_64-linux-musl` option, by switching `dyn` library
`.linkage` property from `.dynamic` to `.static`, a fully static executable can
be obtained. Thanks to `musl` properties, the resulting size of the executable
is smaller than the size of the fully static executable obtained using `gcc`,
in the `build-3` example above.
