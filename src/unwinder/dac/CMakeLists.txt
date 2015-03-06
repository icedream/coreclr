include(${CLR_DIR}/dac.cmake)

add_definitions(-DFEATURE_NO_HOST)

add_library(unwinder_dac ${UNWINDER_SOURCES})
