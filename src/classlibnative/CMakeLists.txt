include_directories(BEFORE "../vm")
include_directories("../inc")
include_directories("../vm/${ARCH_SOURCES_DIR}")
include_directories("../debug/inc")
include_directories("../debug/inc/dump")

add_subdirectory(bcltype)
add_subdirectory(float)

if(WIN32)
  add_subdirectory(nls)
  add_subdirectory(cryptography)
endif(WIN32)

