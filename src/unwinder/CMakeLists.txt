include_directories(BEFORE ${VM_DIR})
include_directories(BEFORE ${VM_DIR}/${ARCH_SOURCES_DIR})
include_directories(BEFORE ${CMAKE_CURRENT_SOURCE_DIR})
include_directories(BEFORE ${CLR_DIR}/src/unwinder)
include_directories(${CLR_DIR}/src/debug/ee)
include_directories(${CLR_DIR}/src/gc)
include_directories(${CLR_DIR}/src/gcdump)
include_directories(${CLR_DIR}/src/debug/daccess)

if(CLR_CMAKE_PLATFORM_UNIX)
  add_compile_options(-fPIC)
endif(CLR_CMAKE_PLATFORM_UNIX)


include_directories(${ARCH_SOURCES_DIR})

if(CLR_CMAKE_PLATFORM_UNIX)
    add_compile_options(-fPIC)
endif(CLR_CMAKE_PLATFORM_UNIX)

set(UNWINDER_SOURCES
    unwinder.cpp
)

if(EXISTS "${ARCH_SOURCES_DIR}/unwinder_${ARCH_SOURCES_DIR}.cpp")
    LIST(APPEND UNWINDER_SOURCES "${ARCH_SOURCES_DIR}/unwinder_${ARCH_SOURCES_DIR}.cpp")
endif()

convert_to_absolute_path(UNWINDER_SOURCES ${UNWINDER_SOURCES})

add_subdirectory(dac)
if(CLR_CMAKE_PLATFORM_UNIX)
    add_subdirectory(wks)
endif(CLR_CMAKE_PLATFORM_UNIX)
