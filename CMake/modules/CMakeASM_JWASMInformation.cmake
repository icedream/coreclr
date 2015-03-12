set(CMAKE_ASM_JWASM_SOURCE_FILE_EXTENSIONS asm)

if(NOT CMAKE_ASM_JWASM_OBJECT_FORMAT)
  set(CMAKE_ASM_JWASM_OBJECT_FORMAT elf)
endif()

set(CMAKE_ASM_JWASM_COMPILE_OBJECT "<CMAKE_ASM_JWASM_COMPILER> <FLAGS> -${CMAKE_ASM_JWASM_OBJECT_FORMAT} -Fo <OBJECT> <SOURCE>")

set(ASM_DIALECT "_JWASM")
include(CMakeASMInformation)
set(ASM_DIALECT)
