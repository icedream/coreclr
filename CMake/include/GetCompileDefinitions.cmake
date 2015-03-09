# Build a list of compiler definitions by putting -D in front of each define.
function(get_compile_definitions DefinitionName)

    set(DEFINITIONS "")

    # Get the current list of definitions
    get_directory_property(COMPILE_DEFINITIONS_LIST COMPILE_DEFINITIONS)

    foreach(DEFINITION IN LISTS COMPILE_DEFINITIONS_LIST)
        if (${DEFINITION} MATCHES "^\\$<\\$<CONFIG:([^>]+)>:([^>]+)>$")
            # The entries that contain generator expressions must have the -D inside of the
            # expression. So we transform e.g. $<$<CONFIG:Debug>:_DEBUG> to $<$<CONFIG:Debug>:-D_DEBUG>
            string(TOUPPER "${CMAKE_MATCH_1}" CONFIG)
            list(APPEND DEFINITIONS "$<$<CONFIG:${CMAKE_MATCH_1}>:-D${CMAKE_MATCH_2}>")
            list(APPEND DEFINITIONS_${CONFIG} "-D${CMAKE_MATCH_2}")
        else()
            list(APPEND DEFINITIONS "-D${DEFINITION}")
            list(APPEND DEFINITIONS_SHARED "-D${DEFINITION}")
        endif()
    endforeach()

    # return to parent scope
    foreach (Config SHARED DEBUG RELEASE RELWITHDEBINFO)
        set(${DefinitionName}_${Config} ${DEFINITIONS_${Config}} PARENT_SCOPE)
    endforeach()
    set(${DefinitionName} ${DEFINITIONS} PARENT_SCOPE)
endfunction(get_compile_definitions)