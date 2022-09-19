import os

os.system(
    "gcc -s -static -nostartfiles -nodefaultlibs -nostdlib -Wl,--build-id=none strlen-avx512.S -o strlen-avx512"
)
