# - Try to find the DIA SDK
# Once done, this will define
#
#  DIASDK_FOUND - system has DIA SDK
#  DIASDK_INCLUDE_DIRS - the DIA SDK include directories
#  DIASDK_LIBRARIES - link these to use DIA SDK
#  DIASDK_DEFINITIONS - compiler switches needed for using DIA SDK

find_package(VS120)
set(VSINSTALLDIR "${VS120_DIR}")

if((NOT VS120_FOUND) OR (NOT EXISTS "${VSINSTALLDIR}/DIA SDK/"))
	# We suspect a corrupted or missing VS2013 installation,
	# fallback to browsing VS2012 to which the VS2013 installer
	# might accidentally have installed DIA SDK.
	find_package(VS110 REQUIRED)
	if(VS110_FOUND)
		set(VSINSTALLDIR "${VS110_DIR}")
	endif()
endif()

set(DIASDK_DIR "${VSINSTALLDIR}/DIA SDK/")
string(REPLACE "//" "/" DIASDK_DIR "${DIASDK_DIR}")
if((NOT "${VSINSTALLDIR}" MATCHES "-NOTFOUND$") AND (EXISTS "${DIASDK_DIR}"))
	find_path(DIASDK_INCLUDE_DIR NAMES "dia2.h"
		HINTS "${DIASDK_DIR}/include")

	find_path(DIASDK_IDL_DIR NAMES "dia2.idl"
		HINTS "${DIASDK_DIR}idl")

	# find_library(DIASDK_LIBRARY_DIAGUIDS NAMES diaguids
	#	HINTS "${DIASDK_DIR}")
	# find_library(DIASDK_LIBRARY_MSDIA120 NAMES msdia120.dll
	#  	HINTS "${VSINSTALLDIR}/DIA SDK/bin/${CMAKE_SYSTEM_PROCESSOR}" "${VSINSTALLDIR}/DIA SDK/bin")

	set(DIASDK_LIBRARIES "")
	if(DIASDK_IDL_DIR MATCHES "\\-NOTFOUND$")
		set(DIASDK_IDL "DIASDK_IDL-NOTFOUND")
	else()
		set(DIASDK_IDL "${DIASDK_IDL_DIR}/dia2.idl")
	endif()
	set(DIASDK_INCLUDE_DIRS ${DIASDK_INCLUDE_DIR})
	set(DIASDK_DEFINITIONS "")
else()
	set(DIASDK_INCLUDE_DIR "DIASDK_INCLUDE_DIR-NOTFOUND")
	set(DIASDK_LIBRARIES "DIASDK_LIBRARIES-NOTFOUND")
	set(DIASDK_IDL "DIASDK_IDL-NOTFOUND")
	set(DIASDK_DIR "DIASDK_DIR-NOTFOUND")
	set(DIASDK_DEFINITIONS "")
endif()

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set DIASDK_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(DIASDK DEFAULT_MSG DIASDK_DIR DIASDK_INCLUDE_DIR)

mark_as_advanced(DIASDK_INCLUDE_DIR DIASDK_LIBRARIES DIASDK_IDL)