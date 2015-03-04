include_directories(BEFORE "../vm")
include_directories("../inc")
include_directories("../vm/${ARCH_SOURCES_DIR}")
include_directories("../debug/inc")
include_directories("../debug/inc/dump")

add_definitions(-DDBG_TARGET_64BIT=${IS_64BIT_BUILD})
add_definitions(-DDBG_TARGET_AMD64=${IS_64BIT_BUILD})
add_definitions(-DDBG_TARGET_WIN64=${IS_64BIT_BUILD})

add_subdirectory(bcltype)
add_subdirectory(float)

if(WIN32)
  add_subdirectory(nls)
  add_subdirectory(cryptography)
endif(WIN32)

