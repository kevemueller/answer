project('answer', 'cpp', version: '0.1', license: 'BSD-2-Clause', meson_version: '>0.56')

add_global_arguments('-v', language : 'cpp')

lib_answer = library('answer', 'answer.cpp', soversion: '1.0', version: '1.0.1') 

main = executable('main', 'main.cpp', link_with: [lib_answer])

# in cross, also check against the native.txt 
if meson.is_cross_build()
    native_lib_answer = library('native_answer', 'answer.cpp', soversion: '1.0', version: '1.0.1', native: true) 
    native_main = executable('native_main', 'main.cpp', link_with: [native_lib_answer], native: true)
endif