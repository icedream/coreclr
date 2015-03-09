# Converts C/C++ header definitions to Assembly-compatible definitions.
function(ConvertHeaderToASM filePath outputVariable)
	message(STATUS "Converting definitions from ${filePath}...")

	set(OUTPUT "")
	file(READ "${filePath}" lines)

	# remove \r
	# note how CMake's implementation of regex does not support "\n"
	# so we have to use the actual \n char
	string(REGEX REPLACE "(\\r$|\\r?\n)" "\n" lines "${lines}")

	# strip comments
	string(REGEX REPLACE "//[^\n]*(\n|\$)" "\n" lines "${lines}")
	#string(REGEX REPLACE "/\\*.*\\*/(\n?|\$)" "\\1" lines "${lines}") # strips out more than just the comment if more than 1 exists, DON'T USE FOR NOW

	# convert to list
	STRING(REGEX REPLACE ";" "\\\\;" lines "${lines}")
  	STRING(REGEX REPLACE "\n" ";" lines "${lines}")

	# process lines
	foreach(line IN LISTS lines)
		if(("${line}" MATCHES "^\\s*#")
			AND (NOT "${line}" MATCHES "^\\s*#\\spragma") # ignore pragmas
			AND (NOT "${line}" MATCHES "^\\s*$")) # ignore blank lines
			if("${line}" MATCHES "^[ \t]*#[ \t]*include[ \t]+[\"']([^\n]+)[\"'][ \t]*(\n|\$)")

				# Convert file path
				file(TO_CMAKE_PATH "${CMAKE_MATCH_1}" SUBINPUT)
				if(NOT EXISTS "${SUBINPUT}") # TODO: replace this with a check if the path is not absolute
					# resolve relative path
					get_filename_component(current_base_dir "${filePath}" DIRECTORY)
					set(SUBINPUT "${current_base_dir}/${SUBINPUT}")
				endif()

				get_filename_component(SUBINPUT "${SUBINPUT}" ABSOLUTE)

				# Expand includes
				ConvertHeaderToASM("${SUBINPUT}" SUBOUTPUT)
				list(APPEND OUTPUT ${SUBOUTPUT})

			elseif("${line}" MATCHES "^[ \t]*#[ \t]*error[ \t]+(.+)(\n|\$)") # error messages
				list(APPEND OUTPUT ".err ${CMAKE_MATCH_1}")

			elseif("${line}" MATCHES "^[ \t]*#[ \t]*(if|ifn?def)[ \t]+(.+)(\n|\$)")
				list(APPEND OUTPUT "${line}") # needs to be preprocessed

			elseif("${line}" MATCHES "^[ \t]*#[ \t]*(else|endif)[ \t]*(\n|\$)")
				list(APPEND OUTPUT "${line}") # needs to be preprocessed

			elseif("${line}" MATCHES "^[ \t]*#[ \t]*define[ \t]+([A-Za-z0-9_]+)[ \t]+(.+)") # does not handle multiline

				# Augment #defines with their MASM equivalent
				set(def_name "${CMAKE_MATCH_1}")
				set(def_value "${CMAKE_MATCH_2}")

				# Note that we do not handle multiline constants

				# Ignore #defines with arguments
				if(NOT "${def_name}" MATCHES "\\(")
					set(HEX_NUMBER_PATTERN "^[ \\t]*0x([0-9A-Fa-f]+)[ \\t]*$")
					set(DECIMAL_NUMBER_PATTERN "^[ \\t]*(\\-?[0-9\\.]+)[ \\t]*$")
					set(TEXT_PATTERN "\"(.*)\"")
					set(def_operation "EQU")

					if (def_value MATCHES "${HEX_NUMBER_PATTERN}")
						set(def_value "0${CMAKE_MATCH_1}h")
					elseif(def_value MATCHES "${TEXT_PATTERN}")
						set(def_operation "TEXTEQU")
						if(WIN32)
							set(def_value "<${CMAKE_MATCH_1}>")
						endif()
					endif()

					list(APPEND OUTPUT "${def_name} ${def_operation} ${def_value}")
				endif()

				list(APPEND OUTPUT "${line}")

			elseif("${line}" MATCHES "^[ \t]*#[ \t]*define[ \t]+([A-Za-z0-9_]+)")
				# #define without value => EQU 1
				set(def_name "${CMAKE_MATCH_1}")
				list(APPEND OUTPUT "${def_name} EQU 1")
				list(APPEND OUTPUT "${line}")
			endif()
		endif()
	endforeach(line)

	# turn list back into proper code string
	string (REGEX REPLACE "([^\\]|^);" "\\1\n" OUTPUT "${OUTPUT}")
	string (REGEX REPLACE "[\\](.)" "\\1" OUTPUT "${OUTPUT}") #fixes escaping

	# return to given variable
	set(${outputVariable} "${OUTPUT}" PARENT_SCOPE)
endfunction()

function(ConvertHeaderToASMFile filePath outputPath)
	ConvertHeaderToASM("${filePath}" OUTPUT)
	file(WRITE "${outputPath}" "${OUTPUT}")
endfunction()