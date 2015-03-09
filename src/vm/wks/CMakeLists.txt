if (WIN32)
  add_precompiled_header(common.h ../common.cpp VM_SOURCES_WKS)
  # mscorlib.cpp does not compile with precompiled header file
  set_source_files_properties(../mscorlib.cpp PROPERTIES COMPILE_FLAGS "/Y-") 
  # .c file cannot use cpp precompiled header 
  set_source_files_properties(../microsoft.comservices_i.c PROPERTIES COMPILE_FLAGS "/Y-") 
endif (WIN32)

add_library(cee_wks ${VM_SOURCES_WKS} ${VM_SOURCES_WKS_AMD64_ASM})

# Get the current list of definitions
get_compile_definitions(DEFINITIONS)

# Extract the definitions for the ASM code. Since there is a bug in the cmake that prevents us from
# using the generator expressions, we split the definitions into lists based on the configuration.
get_directory_property(COMPILE_DEFINITIONS_LIST COMPILE_DEFINITIONS)
foreach(DEFINITION IN LISTS COMPILE_DEFINITIONS_LIST)
    if (${DEFINITION} MATCHES "^\\$<\\$<CONFIG:([^>]+)>:([^>]+)>$")
        # The entry contains generator expression, so insert the definition into a definitions list
        # corresponding to the config
        string(TOUPPER ${CMAKE_MATCH_1} CONFIG)
        set(ASM_DEFINITIONS_${CONFIG} ${ASM_DEFINITIONS_${CONFIG}} ${CMAKE_MATCH_2})
    else()
        list(APPEND ASM_DEFINITIONS ${DEFINITION})
    endif()
endforeach()

# Add defines for the ASM. Unfortunately setting it on the target is ignored for asm by the cmake, so we have
# to set it on the sources.
set_property(SOURCE ${VM_SOURCES_WKS_AMD64_ASM} PROPERTY COMPILE_DEFINITIONS ${ASM_DEFINITIONS})
foreach(CONFIG IN LISTS CMAKE_CONFIGURATION_TYPES)
    string(TOUPPER ${CONFIG} CONFIG)
    set_property(SOURCE ${VM_SOURCES_WKS_AMD64_ASM} PROPERTY COMPILE_DEFINITIONS_${CONFIG} ${ASM_DEFINITIONS_${CONFIG}})
endforeach()

# Convert AsmConstants.h into AsmConstants.inc using CMake
ConvertHeaderToASMFile("${VM_DIR}/${ARCH_SOURCES_DIR}/asmconstants.h" "${CMAKE_CURRENT_BINARY_DIR}/AsmConstants.tmp")

# Preprocess new generated file
message(STATUS "Generating ASM definitions...")
foreach(CONFIG Debug Release RelWithDebInfo)
  # generate preprocessed asm code
  string(TOUPPER "${CONFIG}" CONFIG_UPPER)
  execute_process(COMMAND ${CMAKE_CXX_COMPILER} /nologo ${DEFINITIONS_SHARED} ${DEFINITIONS_${CONFIG_UPPER}} /EP "${CMAKE_CURRENT_BINARY_DIR}/AsmConstants.tmp"
       OUTPUT_FILE "${CMAKE_CURRENT_BINARY_DIR}/AsmConstants_${CONFIG}.inc"
       ERROR_VARIABLE PREPROCESSING_OUTPUT
       RESULT_VARIABLE PREPROCESSING_RESULT)
  if(NOT PREPROCESSING_RESULT EQUAL 0)
    message(FATAL_ERROR "Preprocessing of converted definitions for ${CONFIG} configuration failed with error code ${PREPROCESSING_RESULT}: ${PREPROCESSING_OUTPUT}")
  endif()
  file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/AsmConstants.log")

  # test compile to check for errors
  file(READ "${CMAKE_CURRENT_BINARY_DIR}/AsmConstants_${CONFIG}.inc" TEST_ASM_DEFINITIONS)
  if(CMAKE_TARGET_ARCHITECTURE_CODE STREQUAL "x86")
    set(TEST_ASM_ARCH_CODE ".586")
  else()
    set(TEST_ASM_ARCH_CODE "")
  endif()
  set(TEST_ASM_CODE "${TEST_ASM_ARCH_CODE}
.model flat
${TEST_ASM_DEFINITIONS}
option casemap:none
.code
nop
end")
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/AsmConstantsTest.asm" "${TEST_ASM_CODE}")
  execute_process(COMMAND ${CMAKE_ASM_MASM_COMPILER} ${CMAKE_ASM_MASM_COMPILER_ARG1} ${CMAKE_ASM_MASM_COMPILER_FLAGS} /c /nologo /FoNUL ${DEFINITIONS_SHARED} ${DEFINITIONS_${CONFIG_UPPER}} /W3 AsmConstantsTest.asm
    OUTPUT_VARIABLE PREPROCESSING_OUTPUT
    WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}"
    RESULT_VARIABLE PREPROCESSING_RESULT)
  if(NOT PREPROCESSING_RESULT EQUAL 0)
    message(FATAL_ERROR "Test compile of converted definitions for ${CONFIG} configuration failed with error code ${PREPROCESSING_RESULT} - ${PREPROCESSING_OUTPUT}")
  endif()
  file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/AsmConstantsTest.log")
  file(REMOVE "${CMAKE_CURRENT_BINARY_DIR}/AsmConstantsTest.asm")

endforeach()
file(TO_NATIVE_PATH "${CMAKE_CURRENT_BINARY_DIR}" TARGET_OUTPUT_DIR)
add_custom_command(
  # The correct AsmConstants.inc will be selected in the pre-build phase of the cee_wks build
  TARGET cee_wks PRE_BUILD
  COMMAND copy "${TARGET_OUTPUT_DIR}\\AsmConstants_\$(Configuration).inc" "${TARGET_OUTPUT_DIR}\\AsmConstants.inc"
)

# VERY VERY dirty hack to get Visual Studio to use our own defined ASM compiler instead of hardcoded ml.exe.
# As a matter of fact, this used to be an old trick viruses used on DOS. Heh.
file(TO_NATIVE_PATH "${CMAKE_ASM_MASM_COMPILER}" asm_compiler_native)
set(jwasm_bat_code "")
if(CMAKE_ASM_JWASM_COMPILER_WORKS)
  set(jwasm_bat_code "set compiler_args=%compiler_args:/Ta=%
set compiler_args=%compiler_args:/errorReport:prompt=%
set compiler_args=%compiler_args:/errorReport:none=%
set compiler_args=%compiler_args:/errorReport:queue=%
set compiler_args=%compiler_args:/errorReport:send=%
")
endif()
file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/ml.exe.bat" "@echo off
SetLocal
set compiler_args=%*
${jwasm_bat_code}echo \"${asm_compiler_native}\" ${CMAKE_ASM_MASM_COMPILER_ARG1} ${CMAKE_ASM_MASM_COMPILER_FLAGS} %compiler_args% 1>&2
\"${asm_compiler_native}\" ${CMAKE_ASM_MASM_COMPILER_ARG1} ${CMAKE_ASM_MASM_COMPILER_FLAGS} %compiler_args%
exit /b %errorlevel%")