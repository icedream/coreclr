cmake_minimum_required(VERSION 2.8.12)

project(CoreCLR)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake/modules")

include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/AddPrecompiledHeader.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/ConvertToAbsolutePath.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/GetCompileDefinitions.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/GetIncludeDirectories.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/H2Inc.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/PreprocessDefFile.cmake")
include("${CMAKE_CURRENT_SOURCE_DIR}/CMake/include/TargetArch.cmake")

set(CLR_DIR ${CMAKE_CURRENT_SOURCE_DIR})
set(VM_DIR ${CMAKE_CURRENT_SOURCE_DIR}/src/vm)

# target architecture
# ${CMAKE_TARGET_ARCHITECTURES} will contain x86_64 or i386 or armv5/armv6/armv7
target_architecture(CMAKE_TARGET_ARCHITECTURES)
list(LENGTH CMAKE_TARGET_ARCHITECTURES cmake_target_arch_len)
if(NOT "${cmake_target_arch_len}" STREQUAL "1")
  message(STATUS "Preferring amd64 architecture")
  set(CMAKE_TARGET_ARCHITECTURE_CODE "amd64") # can only happen with Mac OS X in case of x86 and amd64 support
elseif(CMAKE_TARGET_ARCHITECTURES STREQUAL "armv8")
  set(CMAKE_TARGET_ARCHITECTURE_CODE "arm64")
elseif(CMAKE_TARGET_ARCHITECTURES MATCHES arm)
  set(CMAKE_TARGET_ARCHITECTURE_CODE "arm")
else()
  set(CMAKE_TARGET_ARCHITECTURE_CODE "${CMAKE_TARGET_ARCHITECTURES}")
endif()

if(APPLE)
  set(MACOSX_RPATH ON)
  if(CMAKE_VERSION VERSION_EQUAL 3.0 OR CMAKE_VERSION VERSION_GREATER 3.0)
    cmake_policy(SET CMP0042 NEW)
  endif()
endif()

if("${CMAKE_TARGET_ARCHITECTURE_CODE}" MATCHES "64$")
  message(STATUS "Building 64-bit binaries")
  set(IS_64BIT_BUILD 1)
else()
  message(STATUS "Building 32-bit binaries")
  set(IS_64BIT_BUILD 0)
endif()
string(TOUPPER "${CMAKE_TARGET_ARCHITECTURE_CODE}" CMAKE_TARGET_ARCHITECTURE_CODE_UPPER)

#platform
if(WIN32)
  message(STATUS "Detected platform: Windows")

  if(NOT MSVC)
    message(FATAL_ERROR "A Microsoft Visual C/C++ compiler seems to be missing. You need to install Visual Studio 2013 or newer to build this project.")
  endif()

  if(MSVC_VERSION LESS 1800)
    message(FATAL_ERROR "Your current Visual Studio version is too old. You need to install Visual Studio 2013 or newer to build this project.")
  endif()

  set(CLR_CMAKE_PLATFORM_WINDOWS 1)

  # TODO: The following options are set by the razzle build
  # set(OVERRIDE_CMAKE_CXX_FLAGS 1)
  add_compile_options(/TP) # compile all files as C++
  add_compile_options(/FIWarningControl.h) # force include of WarningControl.h
  add_compile_options($<$<CONFIG:RelWithDebInfo>:/Zi> $<$<CONFIG:Debug>:/Zi>) # enable debugging information
  add_compile_options($<$<CONFIG:RelWithDebInfo>:/d2Zi+>) # make optimized builds debugging easier
  # add_compile_options(/nologo) # Suppress Startup Banner
  add_compile_options(/W3) # set warning level to 3
  add_compile_options(/wd4960 /wd4961 /wd4603 /wd4627 /wd4838 /wd4456 /wd4457 /wd4458 /wd4459 /wd4091 /we4640) # specific warnings
  # add_compile_options(/WX) # treat warnings as errors
  add_compile_options($<$<CONFIG:Release>:/Ox> $<$<CONFIG:RelWithDebInfo>:/O2> $<$<CONFIG:Debug>:/Od>) # optimization level
  add_compile_options($<$<CONFIG:Release>:/Oi> $<$<CONFIG:RelWithDebInfo>:/Oi>) # enable intrinsics
  add_compile_options($<$<CONFIG:Release>:/Oy-> $<$<CONFIG:RelWithDebInfo>:/Oy->) # disable suppressing of the creation of frame pointers on the call stack for quicker function calls
  add_compile_options(/U_MT) # undefine the predefined _MT macro
  add_compile_options(/Gz) # __stdcall convention, fixes declaration incompatibilities at non-64bit archs
  add_compile_options(/GF) # enable read-only string pooling
  add_compile_options(/Gm-) # disable minimal rebuild
  add_compile_options(/EHa) # enable C++ EH (w/ SEH exceptions)
  add_compile_options(/Zp8) # pack structs on 8-byte boundary
  add_compile_options(/GS) # enable security checks
  add_compile_options(/Gy) # separate functions for linker
  add_compile_options(/Zc:wchar_t-) # C++ language conformance: wchar_t is NOT the native type, but a typedef
  add_compile_options(/Zc:forScope) # C++ language conformance: enforce Standard C++ for scoping rules
  add_compile_options(/GR-) # disable C++ RTTI
  add_compile_options(/FC) # use full pathnames in diagnostics
  add_compile_options(/Zl) # omit default library name in .OBJ
  add_compile_options(/MP) # Build with Multiple Processes (number of processes equal to the number of processors)
  add_compile_options(/GS) # Buffer Security Check
  add_compile_options(/Zm200) # Specify Precompiled Header Memory Allocation Limit of 150MB

  if (IS_64BIT_BUILD EQUAL 1)
    # The generator expression in the following command means that the /homeparams option is added only for debug builds
    add_compile_options($<$<CONFIG:Debug>:/homeparams>) # Force parameters passed in registers to be written to the stack
  endif (IS_64BIT_BUILD EQUAL 1)

  # Disable the following line for UNIX altjit on Windows
  set(CMAKE_CXX_STANDARD_LIBRARIES "") # do not link against standard win32 libs i.e. kernel32, uuid, user32, etc.

  # Linker flags
  #
  # Disable the following line for UNIX altjit on Windows
  set(CMAKE_SHARED_LINKER_FLAGS "/NODEFAULTLIB") #do not use default libraries when resolving external references
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /MANIFEST:NO") #Do not create Side-by-Side Assembly Manifest
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SUBSYSTEM:WINDOWS,6.00") #windows subsystem
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /LARGEADDRESSAWARE") # can handle addresses larger than 2 gigabytes
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /RELEASE") #sets the checksum in the header
  if (NOT IS_64BIT_BUILD)
    set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /SAFESEH:NO") #Image does not have Safe Exception Handlers..valid only for x86
  endif (NOT IS_64BIT_BUILD)
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /NXCOMPAT") #Compatible with Data Execution Prevention
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /DYNAMICBASE") #Use address space layout randomization
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /DEBUGTYPE:cv,fixup") #debugging format
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /PDBCOMPRESS") #shrink pdb size
  set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF /IGNORE:4197,4013,4254,4070,4221")

  set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /DEBUG /PDBCOMPRESS")

  # Debug build specific flags
  set(CMAKE_SHARED_LINKER_FLAGS_DEBUG "/NOVCFEATURE")

  # Release build specific flags
  set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${CMAKE_SHARED_LINKER_FLAGS_RELEASE} /LTCG")

  # ReleaseWithDebugInfo build specific flags
  set(CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO "${CMAKE_SHARED_LINKER_FLAGS_RELWITHDEBINFO} /LTCG")

  # Windows-specific libraries
  set(STATIC_MT_CRT_LIB  "libcmt$<$<CONFIG:Debug>:d>.lib")
  set(STATIC_MT_CPP_LIB  "libcpmt$<$<CONFIG:Debug>:d>.lib")

  add_definitions(-D_CRT_SECURE_NO_WARNINGS)
  add_definitions(-DFEATURE_CLASSIC_COMINTEROP)
  add_definitions(-DFEATURE_APPX)
  add_definitions(-DFEATURE_COMINTEROP)
  add_definitions(-DFEATURE_COMINTEROP_APARTMENT_SUPPORT)
  add_definitions(-DFEATURE_COMINTEROP_UNMANAGED_ACTIVATION)
  add_definitions(-DFEATURE_COMINTEROP_WINRT_MANAGED_ACTIVATION)
  add_definitions(-DFEATURE_CRYPTO)
  add_definitions(-DFEATURE_EVENT_TRACE=1)
  add_definitions(-DFEATURE_HIJACK)
  add_definitions(-DFEATURE_ISOSTORE)
  add_definitions(-DFEATURE_ISOSTORE_LIGHT)
  add_definitions(-DFEATURE_LEGACYNETCFCRYPTO)
  add_definitions(-DFEATURE_LEGACYSURFACE)
  add_definitions(-DFEATURE_RANDOMIZED_STRING_HASHING)
  add_definitions(-DFEATURE_STRONGNAME_TESTKEY_ALLOWED)
  add_definitions(-DFEATURE_VERSIONING_LOG)
  add_definitions(-DFEATURE_X509)
  add_definitions(-DFEATURE_X509_SECURESTRINGS)
  add_definitions(-DPROFILING_SUPPORTED)

  # Disable the following for UNIX altjit on Windows
  add_definitions(-DFEATURE_MERGE_JIT_AND_ENGINE)

  # Disable edit and continue on Linux
  add_definitions(-DEnC_SUPPORTED)
elseif(UNIX)
  # Unix-type system

  set(CLR_CMAKE_PLATFORM_UNIX 1)
  enable_language(ASM)

  if(IS_64BIT_BUILD EQUAL 1)
    add_definitions(-DBIT64=1)
    add_definitions(-DFEATURE_PAL)
  endif(IS_64BIT_BUILD EQUAL 1)
  add_definitions(-DDBG_TARGET_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_UNIX)
  add_definitions(-DPLATFORM_UNIX=1)
  add_definitions(-DFEATURE_PAL_SXS)
  add_definitions(-DFEATURE_IMPLICIT_TLS)
  add_definitions(-DDISABLE_CONTRACTS)
  add_definitions(-DFEATURE_STUBS_AS_IL)
  add_definitions(-DUNIX_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_ABI)

  # C11 standard
  add_compile_options(-std=c11)

  # Debug info
  add_compile_options($<$<CONFIG:Debug>:-g> $<$<CONFIG:RelWithDebInfo>:-g>)

  # Optimization level
  add_compile_options($<$<CONFIG:Debug>:-O0> $<$<CONFIG:Release>:-O3> $<$<CONFIG:RelWithDebInfo>:-O2>)

  # The -ferror-limit is helpful during the porting, it makes sure the compiler doesn't stop
  # after hitting just about 20 errors.
  add_compile_options(-ferror-limit=4096)

  # Disabled warnings
  add_compile_options(-Wno-reorder)
  add_compile_options(-Wno-ignored-attributes)
  add_compile_options(-Wno-unknown-pragmas)
  add_compile_options(-Wno-unused-private-field)
  add_compile_options(-Wno-new-returns-null)
  add_compile_options(-Wno-dangling-else)
  add_compile_options(-Wno-implicit-exception-spec-mismatch)
  add_compile_options(-Wno-deprecated-register)
  add_compile_options(-Wno-parentheses)
  add_compile_options(-Wno-overloaded-virtual)
  add_compile_options(-Wno-unused-variable)
  add_compile_options(-Wno-missing-declarations)
  add_compile_options(-Wno-switch)
  add_compile_options(-Wno-extern-initializer)
  add_compile_options(-Wno-microsoft)
  add_compile_options(-Wno-mismatched-tags)
  add_compile_options(-Wno-ignored-qualifiers)
  add_compile_options(-Wno-tautological-constant-out-of-range-compare)
  add_compile_options(-Wno-c++11-compat-deprecated-writable-strings)
  add_compile_options(-Wno-unneeded-internal-declaration)
  add_compile_options(-Wno-tautological-compare)
  add_compile_options(-Wno-constant-logical-operand)
  add_compile_options(-Wno-unused-function)
  add_compile_options(-Wno-extra-tokens)
  add_compile_options(-Wno-self-assign)
  add_compile_options(-Wno-bitfield-constant-conversion)
  add_compile_options(-Wno-unused-value)
  add_compile_options(-Wno-unknown-warning-option)

  #These seem to indicate real issues
  add_compile_options(-Wno-invalid-offsetof)
  add_compile_options(-Wno-return-type)
  add_compile_options(-Wno-dynamic-class-memaccess)
  add_compile_options(-Wno-int-to-pointer-cast)
  add_compile_options(-Wno-delete-non-virtual-dtor)
  add_compile_options(-Wno-enum-compare)

  # The -fms-extensions enable the stuff like __if_exists, __declspec(uuid()), etc.
  add_compile_options(-fms-extensions )
  #-fms-compatibility      Enable full Microsoft Visual C++ compatibility
  #-fms-extensions         Accept some non-standard constructs supported by the Microsoft compiler
  # The newer version of clang hits this seemly benign error that this disables.
  add_compile_options(-Wno-incompatible-ms-struct)

  if(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # Linux
    message(STATUS "Detected platform: Linux")
    set(CLR_CMAKE_PLATFORM_LINUX 1)

    add_definitions(-D__LINUX__=1)
    if(IS_64BIT_BUILD EQUAL 1)
      add_definitions(-DLINUX64)
    else(IS_64BIT_BUILD EQUAL 1)
      add_definitions(-DLINUX32)
    endif(IS_64BIT_BUILD EQUAL 1)

  elseif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")
    # Mac OS X
    message(STATUS "Detected platform: Darwin/Mac OS X")
    add_definitions(-D_XOPEN_SOURCE)

    # Enable @rpath support on Mac OS X for shared libraries.
    set(MACOSX_RPATH ON)
    if(CMAKE_VERSION VERSION_EQUAL 3.0 OR CMAKE_VERSION VERSION_GREATER 3.0)
      cmake_policy(SET CMP0042 NEW)
    endif()

    set(CLR_CMAKE_PLATFORM_DARWIN 1)
    set(CMAKE_ASM_COMPILE_OBJECT "${CMAKE_C_COMPILER} <FLAGS> <DEFINES> -o <OBJECT> -c <SOURCE>")

  endif(CMAKE_SYSTEM_NAME STREQUAL "Darwin")

else()
  # Unsupported
  message(FATAL_ERROR "The platform ${CMAKE_SYSTEM_NAME} is not supported by CoreCLR yet.")

endif()

# ASM compiler stuff
set(CMAKE_ASM_MASM_COMPILER_FLAGS "${CMAKE_ASM_MASM_COMPILER_FLAGS} /Zm") # We need to be able to declare scoped code labels => MASM 5.10 compat
if(NOT IS_64BIT_BUILD)
  set(CMAKE_ASM_MASM_COMPILER_FLAGS "${CMAKE_ASM_MASM_COMPILER_FLAGS} /FPi")
endif()
if(MSVC)
  enable_language(ASM_JWASM)
  if(CMAKE_ASM_JWASM_COMPILER_WORKS)
    message(STATUS "Now using JWASM compiler: ${CMAKE_ASM_JWASM_COMPILER}")
    # Since JWASM is MASM-compatible, we can just use it as MASM compiler as well
    set(CMAKE_ASM_MASM_COMPILER "${CMAKE_ASM_JWASM_COMPILER}")
    set(CMAKE_ASM_MASM_COMPILER_ARG1 "${CMAKE_ASM_MASM_COMPILER_ARG1} ${CMAKE_ASM_JWASM_COMPILER_ARG1}")
    set(CMAKE_ASM_MASM_COMPILER_FLAGS "${CMAKE_ASM_MASM_COMPILER_FLAGS} ${CMAKE_ASM_JWASM_FLAGS}")
    set(CMAKE_ASM_MASM_COMPILER_LOADED "${CMAKE_ASM_JWASM_COMPILER_LOADED}")
    set(CMAKE_ASM_MASM_COMPILER_ID "${CMAKE_ASM_JWASM_COMPILER_ID}")
    set(CMAKE_ASM_MASM_COMPILER_ENV_VAR "${CMAKE_ASM_JWASM_COMPILER_ENV_VAR}")
    set(CMAKE_ASM_MASM_IGNORE_EXTENSIONS "${CMAKE_ASM_JWASM_IGNORE_EXTENSIONS}")
    set(CMAKE_ASM_MASM_LINKER_PREFERENCE "${CMAKE_ASM_JWASM_LINKER_PREFERENCE}")
    enable_language(ASM_MASM)
    set(CMAKE_ASM_MASM_COMPILER_FLAGS "-Zg -Zne -Zv8 -coff ${CMAKE_ASM_MASM_COMPILER_FLAGS}") # try to stay as close to MASM as possible
    if(IS_64BIT_BUILD)
      set(CMAKE_ASM_MASM_COMPILER_FLAGS "-win64 -mf ${CMAKE_ASM_MASM_COMPILER_FLAGS}") # compile 64-bit and use flat model by default
    endif()
  endif()
  if(CMAKE_ASM_JWASM_COMPILER_WORKS)
    message(STATUS "Now using MASM-compatible JWasm compiler: ${CMAKE_ASM_MASM_COMPILER}")
  elseif(CMAKE_ASM_MASM_COMPILER_WORKS)
    message(STATUS "Now using MASM compiler: ${CMAKE_ASM_MASM_COMPILER}")
  else()
    enable_language(ASM)
    message(STATUS "Now using ASM compiler: ${CMAKE_ASM_COMPILER}")
  endif()
else()
  enable_language(ASM)
  message(STATUS "Now using ASM compiler: ${CMAKE_ASM_COMPILER}")
endif(MSVC)

# Includes

# default CMAKE_BUILD_TYPE. On Windows use multiple configurations.
if(NOT CMAKE_BUILD_TYPE)
  if(WIN32)
    set(CMAKE_BUILD_TYPE "DEBUG;RELEASE;RELWITHDEBINFO" CACHE STRING "Build type (Debug, Release, RelWithDebInfo - use \";\" separation for multi-configurations)" FORCE)
  else()
    set(CMAKE_BUILD_TYPE "RELEASE" CACHE STRING "Build type (Debug, Release, RelWithDebInfo)" FORCE)
  endif()
endif()
set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "DEBUG;RELEASE;RELWITHDEBINFO")

# PAL system
add_subdirectory(src/debug/debug-pal)
if(CLR_CMAKE_PLATFORM_UNIX)
  add_subdirectory(src/ToolBox/SOS/lldbplugin)
  add_subdirectory(src/pal)
  add_subdirectory(src/coreclr/hosts/unixcorerun)
endif(CLR_CMAKE_PLATFORM_UNIX)
add_subdirectory(src/pal/prebuilt/inc) # Add this subdir. We install the headers for the jit.
include_directories("src/pal/prebuilt/inc") # Include the basic prebuilt headers - required for getting fileversion resource details.
if(CLR_CMAKE_PLATFORM_UNIX)
  include_directories("src/pal/inc")
  include_directories("src/pal/inc/rt")
  include_directories("src/pal/src/safecrt")
endif(CLR_CMAKE_PLATFORM_UNIX)

# General definitions
add_definitions(-D_CRT_STDIO_ARBITRARY_WIDE_SPECIFIERS)
add_definitions(-DDEV10)
add_definitions(-DWIN32)
add_definitions(-DWIN32_LEAN_AND_MEAN=1)
add_definitions(-D_WIN32_WINNT=0x0602)
add_definitions(-D_WIN32_IE=0x0900)
add_definitions(-DDEVL=1)
add_definitions(-DWINNT=1)
add_definitions(-DNT_INST=0)
add_definitions(-DCONDITION_HANDLING=1)
add_definitions(-DNTDDI_VERSION=NTDDI_WIN8)
add_definitions(-DNTMAKEENV)
add_definitions(-D_BLD_CLR)
add_definitions(-DWINVER=0x0602)
add_definitions(-DDEBUGGING_SUPPORTED)
add_definitions(-DFEATURE_APPDOMAIN_RESOURCE_MONITORING)
add_definitions(-DFEATURE_ARRAYSTUB_AS_IL)
add_definitions(-DFEATURE_ASYNC_IO)
add_definitions(-DFEATURE_BCL_FORMATTING)
add_definitions(-DFEATURE_COLLECTIBLE_TYPES)
add_definitions(-DFEATURE_CORECLR)
add_definitions(-DFEATURE_CORESYSTEM)
add_definitions(-DFEATURE_CORRUPTING_EXCEPTIONS)
add_definitions(-DFEATURE_EXCEPTIONDISPATCHINFO)
add_definitions(-DFEATURE_FRAMEWORK_INTERNAL)
add_definitions(-DFEATURE_HOST_ASSEMBLY_RESOLVER)
add_definitions(-DFEATURE_HOSTED_BINDER)
add_definitions(-DFEATURE_ISYM_READER)
add_definitions(-DFEATURE_LEGACYNETCF)
add_definitions(-DFEATURE_LEGACYNETCF_DBG_HOST_CONTROL)
add_definitions(-DFEATURE_LEGACYNETCFFAS)
add_definitions(-DFEATURE_LOADER_OPTIMIZATION)
add_definitions(-DFEATURE_MANAGED_ETW)
add_definitions(-DFEATURE_MANAGED_ETW_CHANNELS)
add_definitions(-DFEATURE_MAIN_CLR_MODULE_USES_CORE_NAME)
add_definitions(-DFEATURE_MERGE_CULTURE_SUPPORT_AND_ENGINE)
add_definitions(-DFEATURE_NORM_IDNA_ONLY)
add_definitions(-DFEATURE_PREJIT)
add_definitions(-DFEATURE_STANDALONE_SN)
add_definitions(-DFEATURE_STRONGNAME_DELAY_SIGNING_ALLOWED)
add_definitions(-DFEATURE_STRONGNAME_MIGRATION)
add_definitions(-DFEATURE_SVR_GC)
add_definitions(-DFEATURE_SYNTHETIC_CULTURES)
add_definitions(-DFEATURE_VERSIONING)
add_definitions(-DFEATURE_WIN32_REGISTRY)
add_definitions(-DFEATURE_WINDOWSPHONE)
add_definitions(-DFEATURE_WINMD_RESILIENT)
add_definitions(-DFEATURE_MULTICOREJIT)
add_definitions(-DFEATURE_USE_ASM_GC_WRITE_BARRIERS)
add_definitions(-DFEATURE_SYMDIFF)

if(CLR_CMAKE_PLATFORM_UNIX)
    add_definitions(-DFEATURE_DBGIPC_TRANSPORT_DI)
    add_definitions(-DFEATURE_DBGIPC_TRANSPORT_VM)
endif(CLR_CMAKE_PLATFORM_UNIX)
add_definitions(-D_SECURE_SCL=0)
add_definitions(-D_NEW_SDK=1)
add_definitions(-DOFFICIAL_BUILD=0)
add_definitions(-DBETA=0)
add_definitions(-DFX_BRANCH_SYNC_COUNTER_VALUE=0)
add_definitions(-DUNICODE)
add_definitions(-D_UNICODE)
add_definitions(-DDBG_TARGET_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}=1)
add_definitions(-D_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_)
add_definitions(-D_TARGET_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_=1)
if (IS_64BIT_BUILD EQUAL 1)
  add_definitions(-D_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_)
  add_definitions(-D_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_SIMULATOR_)
  add_definitions(-D_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_SIMULATOR_PERF_)
  add_definitions(-D_${CMAKE_TARGET_ARCHITECTURE_CODE_UPPER}_WORKAROUND_)
  add_definitions(-DDBG_TARGET_64BIT=1)
  add_definitions(-DWIN64)
  add_definitions(-D_WIN64)
  add_definitions(-D_SKIP_IF_SIMULATOR_)
endif (IS_64BIT_BUILD EQUAL 1)

# debug build flags
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:_DEBUG> $<$<CONFIG:Debug>:_DBG> $<$<CONFIG:Debug>:DEBUG> $<$<CONFIG:Release>:NDEBUG> $<$<CONFIG:RelWithDebInfo>:NDEBUG>)
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:BUILDENV_CHECKED=1>)

# use the shipped implementation code for intrinsics
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Release>:INTERLOCKEDOPS_INTRINSICS> $<$<CONFIG:RelWithDebInfo>:INTERLOCKEDOPS_INTRINSICS>)

# friendly name of build environment
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Release>:URTBLDENV_FRIENDLY=Retail> $<$<CONFIG:RelWithDebInfo>:URTBLDENV_FRIENDLY=Retail> $<$<CONFIG:Debug>:URTBLDENV_FRIENDLY=Checked>)

# barrier checks
set_property(DIRECTORY APPEND PROPERTY COMPILE_DEFINITIONS $<$<CONFIG:Debug>:WRITE_BARRIER_CHECK=1>)

if(CMAKE_TARGET_ARCHITECTURE_CODE STREQUAL "x86")
  set(ARCH_SOURCES_DIR i386)
elseif(CMAKE_TARGET_ARCHITECTURE_CODE MATCHES "arm")
  set(ARCH_SOURCES_DIR "arm")
elseif(CMAKE_TARGET_ARCHITECTURE_CODE MATCHES "amd64")
  set(ARCH_SOURCES_DIR "amd64")
endif()

# on to subprojects
add_subdirectory(src)
