function(GetVC12Vars RESULT_NAME)
	set(${RESULT_NAME}_INSTALLED 0)

	if(WIN32)
		message(STATUS "Checking for Visual Studio 2013")

		# Check %VS120COMNTOOLS%
		STRING(REGEX REPLACE "\\\\\\\\" "\\\\" VCVARSALLBAT "$ENV{VS120COMNTOOLS}/../../VC/vcvarsall.bat")
		STRING(REGEX REPLACE "\\\\" "/" VCVARSALLBAT_CMAKE "${VCVARSALLBAT}")
		if(EXISTS "${VCVARSALLBAT_CMAKE}")
			# Run vcvarsall.bat and set variables accordingly
			set(vcvars_bat_code "
@call \"${VCVARSALLBAT}\"

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
				OUTPUT_VARIABLE process_output
				OUTPUT_STRIP_TRAILING_WHITESPACE)
			file(REMOVE "${CMAKE_BINARY_DIR}/vcvars.bat")
			file(WRITE "${CMAKE_BINARY_DIR}/vcvars.cmake" "${process_output}")
			include("${CMAKE_BINARY_DIR}/vcvars.cmake")
			#file(REMOVE "${CMAKE_BINARY_DIR}/vcvars.cmake")
		else()
			message(STATUS "Checking for Visual Studio 2013 - ${VCVARSALLBAT} not existent")
		endif()

		if(${${RESULT_NAME}_INSTALLED})
			message(STATUS "Checking for Visual Studio 2013 - found in ${${RESULT_NAME}_VSINSTALLDIR}")
		else()
			message(STATUS "Checking for Visual Studio 2013 - NOT found")
		endif()
	else()
		message(STATUS "Skipping Visual Studio 2013 check")
	endif(WIN32)

endfunction()