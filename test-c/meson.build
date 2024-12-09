project('answer', 'c', version: '0.1', license: 'BSD-2-Clause', meson_version: '>0.56')

lib_answer = library('answer', 'answer.c', soversion: '1.0', version: '1.0.1') 

main = executable('main', 'main.c', link_with: [lib_answer])

# in cross, also check against the native.txt 
if meson.is_cross_build()
    native_lib_answer = library('native_answer', 'answer.c', soversion: '1.0', version: '1.0.1', native: true) 
    native_main = executable('native_main', 'main.c', link_with: [native_lib_answer], native: true)
endif