function(GetVC11Vars RESULT_NAME)
	set(${RESULT_NAME}_INSTALLED 0)
	set(${RESULT_NAME}_INSTALLED ${${RESULT_NAME}_INSTALLED} PARENT_SCOPE)

	if(WIN32)
		# TODO: Support ARM cross-build
		if(CMAKE_TARGET_ARCHITECTURE_CODE STREQUAL "amd64")
			if (CMAKE_CL_64)
				set(${RESULT_NAME}_TOOLCHAIN "amd64")
			else()
				set(${RESULT_NAME}_TOOLCHAIN "x86_amd64")
			endif()
		elseif(CMAKE_TARGET_ARCHITECTURE_CODE STREQUAL "arm")
			set(${RESULT_NAME}_TOOLCHAIN "arm")
		elseif(CMAKE_TARGET_ARCHITECTURE_CODE STREQUAL "arm64")
			set(${RESULT_NAME}_TOOLCHAIN "arm")
		else()
			if (CMAKE_CL_64)
				set(${RESULT_NAME}_TOOLCHAIN "amd64_x86")
			else()
				set(${RESULT_NAME}_TOOLCHAIN "x86")
			endif()
		endif()
		set(${RESULT_NAME}_TOOLCHAIN "${${RESULT_NAME}_TOOLCHAIN}" PARENT_SCOPE)

		# Check %VS110COMNTOOLS%
		file(TO_CMAKE_PATH "$ENV{VS110COMNTOOLS}" VS110COMNTOOLSDIR)
		if((VS110COMNTOOLSDIR STREQUAL "") OR (NOT EXISTS "${VS110COMNTOOLSDIR}/"))
			# assume default location
			# workaround for CMake bug #10669 - http://www.cmake.org/Bug/print_bug_page.php?bug_id=10669
			set(ENVNAME_PROGRAMFILES_X86 "PROGRAMFILES(X86)")
			if((ENV{${ENVNAME_PROGRAMFILES_X86}} STREQUAL "") OR (NOT EXISTS "$ENV{${ENVNAME_PROGRAMFILES_X86}}/"))
				file(TO_CMAKE_PATH "$ENV{PROGRAMFILES}" PROGRAMFILESX86)
			else()
				file(TO_CMAKE_PATH "$ENV{${ENVNAME_PROGRAMFILES_X86}}" PROGRAMFILESX86)
			endif()
			set(VS110COMNTOOLSDIR "${PROGRAMFILESX86}/Microsoft Visual Studio 11.0/Common7/Tools")
		endif()
		string(REGEX REPLACE "//" "/" VCVARSALLBAT_CMAKE "${VS110COMNTOOLSDIR}/../../VC/vcvarsall.bat")

		file(TO_NATIVE_PATH "${VCVARSALLBAT_CMAKE}" VCVARSALLBAT)
		if(EXISTS "${VCVARSALLBAT_CMAKE}")
			# Run vcvarsall.bat and set variables accordingly
			set(vcvars_bat_code "
@call \"${VCVARSALLBAT}\" ${${RESULT_NAME}_TOOLCHAIN}

@echo set(${RESULT_NAME}_INSTALLED 1)
@echo set(${RESULT_NAME}_INCLUDE \"%INCLUDE:\\=\\\\%\")
@echo set(${RESULT_NAME}_LIB \"%LIB:\\=\\\\%\")
@echo set(${RESULT_NAME}_LIBPATH \"%LIBPATH:\\=\\\\%\")
@echo set(${RESULT_NAME}_PATH \"%PATH:\\=\\\\%\")
@echo set(${RESULT_NAME}_VSINSTALLDIR \"%VSINSTALLDIR:\\=/%\")
@echo set(${RESULT_NAME}_VCINSTALLDIR \"%VCINSTALLDIR:\\=/%\")

@echo set(${RESULT_NAME}_INSTALLED \${${RESULT_NAME}_INSTALLED} PARENT_SCOPE)
@echo set(${RESULT_NAME}_INCLUDE \"\${${RESULT_NAME}_INCLUDE}\" PARENT_SCOPE)
@echo set(${RESULT_NAME}_LIB \"\${${RESULT_NAME}_LIB}\" PARENT_SCOPE)
@echo set(${RESULT_NAME}_LIBPATH \"\${${RESULT_NAME}_LIBPATH}\" PARENT_SCOPE)
@echo set(${RESULT_NAME}_PATH \"\${${RESULT_NAME}_PATH}\" PARENT_SCOPE)
@echo set(${RESULT_NAME}_VSINSTALLDIR \"\${${RESULT_NAME}_VSINSTALLDIR}\" PARENT_SCOPE)
@echo set(${RESULT_NAME}_VCINSTALLDIR \"\${${RESULT_NAME}_VCINSTALLDIR}\" PARENT_SCOPE)
")
			file(WRITE "${CMAKE_BINARY_DIR}/vcvars.bat" "${vcvars_bat_code}")
			execute_process(COMMAND cmd /c @call "${CMAKE_BINARY_DIR}/vcvars.bat"
				OUTPUT_FILE "${CMAKE_BINARY_DIR}/vcvars.cmake"
				OUTPUT_STRIP_TRAILING_WHITESPACE)
			file(REMOVE "${CMAKE_BINARY_DIR}/vcvars.bat")
			include("${CMAKE_BINARY_DIR}/vcvars.cmake")
			file(REMOVE "${CMAKE_BINARY_DIR}/vcvars.cmake")

			if(EXISTS "${${RESULT_NAME}_VCINSTALLDIR}${${RESULT_NAME}_TOOLCHAIN}/ml.exe")
				set(ML "${${RESULT_NAME}_VCINSTALLDIR}${${RESULT_NAME}_TOOLCHAIN}/ml.exe")
			elseif(EXISTS "${${RESULT_NAME}_VCINSTALLDIR}/${${RESULT_NAME}_TOOLCHAIN}/ml.exe")
				set(ML "${${RESULT_NAME}_VCINSTALLDIR}/${${RESULT_NAME}_TOOLCHAIN}/ml.exe")
			elseif(EXISTS "${${RESULT_NAME}_VCINSTALLDIR}${${RESULT_NAME}_TOOLCHAIN}/ml64.exe")
				set(ML "${${RESULT_NAME}_VCINSTALLDIR}${${RESULT_NAME}_TOOLCHAIN}/ml64.exe")
			elseif(EXISTS "${${RESULT_NAME}_VCINSTALLDIR}/${${RESULT_NAME}_TOOLCHAIN}/ml64.exe")
				set(ML "${${RESULT_NAME}_VCINSTALLDIR}/${${RESULT_NAME}_TOOLCHAIN}/ml64.exe")
			else()
				set(ML "${${RESULT_NAME}_VCINSTALLDIR}/ml.exe")
			endif()

			string(REPLACE "//" "/" ML "${ML}")
			#string(REPLACE "/" "\\" ML "${ML}")
			set(${RESULT_NAME}_ML "${ML}" PARENT_SCOPE)

			if ("${ML}" MATCHES "64\\.exe$")
				set(${RESULT_NAME}_ML_IS64 1 PARENT_SCOPE)
			else()
				set(${RESULT_NAME}_ML_IS64 0 PARENT_SCOPE)
			endif()
		endif()
	else()
		message(STATUS "Skipping Visual Studio 2013 check")
	endif(WIN32)
endfunction()

# use vcvarsall.bat
GetVC11Vars(_VS110)

if(${_VS110_INSTALLED})
	set(VS110_DIR "${_VS110_VSINSTALLDIR}")
	set(VS110_VC_DIR "${_VS110_VCINSTALLDIR}")
	set(VS110_PATH "${_VS110_PATH}")
	set(VS110_LIB "${_VS110_LIB}")
	set(VS110_LIBPATH "${_VS110_LIBPATH}")
	set(VS110_INCLUDE "${_VS110_INCLUDE}")
	set(VS110_ML_IS64 "${_VS110_ML_IS64}")
	set(VS110_ML "${_VS110_ML}")
endif()

include(FindPackageHandleStandardArgs)
# handle the QUIETLY and REQUIRED arguments and set VS110_FOUND to TRUE
# if all listed variables are TRUE
find_package_handle_standard_args(VS110 DEFAULT_MSG VS110_DIR _VS110_INSTALLED)

mark_as_advanced(VS110_DIR VS110_VC_DIR VS110_PATH VS110_LIB VS110_LIB VS110_LIBPATH VS110_INCLUDE VS110_ML_IS64 VS110_ML)