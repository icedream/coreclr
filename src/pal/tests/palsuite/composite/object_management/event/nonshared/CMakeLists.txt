cmake_minimum_required(VERSION 2.8.12.2)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(SOURCES
  event.c
  main.c
)

add_executable(paltest_event_nonshared
  ${SOURCES}
)

add_dependencies(paltest_event_nonshared CoreClrPal)

target_link_libraries(paltest_event_nonshared
  pthread
  rt
  m
  CoreClrPal
)
