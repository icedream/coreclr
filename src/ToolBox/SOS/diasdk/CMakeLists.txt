# replace backslashes in path with forward slash
if("$ENV{VSINSTALLDIR}" STREQUAL "")
	if((NOT VS12_INSTALLED) OR ("${VS12_VSINSTALLDIR}" STREQUAL ""))
		message(FATAL_ERROR "Could not find Visual Studio 2013 installation directory. You probably need to run vcvarsall.bat first or install Visual Studio 2013.")
	else()
		set(VSINSTALLDIR "${VS12_VSINSTALLDIR}")
	endif()
else()
	STRING(REGEX REPLACE "\\\\" "/" VSINSTALLDIR $ENV{VSINSTALLDIR} )
endif()

# Generate managed type lib from dia2.idl
add_custom_target(dialib ALL
    # generate tlb file from idl
    COMMAND midl.exe /I"${VSINSTALLDIR}DIA SDK/include" /tlb ${CMAKE_CURRENT_BINARY_DIR}/dia2.tlb  /Zp8  "${VSINSTALLDIR}DIA SDK/idl/dia2.idl"
    # run tlbimp to generate managed type library
    COMMAND TlbImp.exe /silent /namespace:Dia /unsafe /strictref:nopia ${CMAKE_CURRENT_BINARY_DIR}/dia2.tlb /out:${CMAKE_CURRENT_BINARY_DIR}/dialib.dll
    COMMENT Generating managed type library from dia2.idl
)

# In order to use dialib.dll as library target it needs to be imported into cmake
# Target is used in ToolBox/SOS/dactablegen/cmakelists.txt
add_library(dialib_dll SHARED IMPORTED GLOBAL)
set_property(TARGET dialib_dll PROPERTY IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/dialib.dll)
