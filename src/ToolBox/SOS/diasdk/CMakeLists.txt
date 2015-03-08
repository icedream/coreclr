# get DIA SDK path
find_package(DIASDK REQUIRED)

file(TO_NATIVE_PATH "${DIASDK_INCLUDE_DIR}" DIASDK_INCLUDE_DIR_CMAKE)
file(TO_NATIVE_PATH "${DIASDK_IDL}" DIASDK_IDL)

# Generate managed type lib from dia2.idl
add_custom_target(dialib ALL
    # generate tlb file from idl
    COMMAND midl.exe /I"${DIASDK_INCLUDE_DIR_CMAKE}" /tlb "${CMAKE_CURRENT_BINARY_DIR}/dia2.tlb" /Zp8 "${DIASDK_IDL}"
    # run tlbimp to generate managed type library
    COMMAND TlbImp.exe /silent /namespace:Dia /unsafe /strictref:nopia "${CMAKE_CURRENT_BINARY_DIR}/dia2.tlb" /out:"${CMAKE_CURRENT_BINARY_DIR}/dialib.dll"
    COMMENT Generating managed type library from dia2.idl
)

# In order to use dialib.dll as library target it needs to be imported into cmake
# Target is used in ToolBox/SOS/dactablegen/cmakelists.txt
add_library(dialib_dll SHARED IMPORTED GLOBAL)
set_property(TARGET dialib_dll PROPERTY IMPORTED_LOCATION "${CMAKE_CURRENT_BINARY_DIR}/dialib.dll")
