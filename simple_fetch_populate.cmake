# cmake/SimplePopulate.cmake
#
# Usage:
#   Simple_Fetch_Populate(<NAME> <REPO|owner/repo|url> <GIT_TAG>
#                             <INTERFACE_TARGET> [INCLUDE_SUBDIR <subdir>])
#
# Example:
#   Simple_Fetch_Populate(rapidjson Tencent/rapidjson v1.1.0 RapidJSON::rapidjson
#                             INCLUDE_SUBDIR include)
#
function(Simple_Fetch_Populate NAME REPO GIT_TAG INTERFACE_TARGET)
	set(options "")
	set(oneValueArgs INCLUDE_SUBDIR)
	cmake_parse_arguments(_sp "" "${oneValueArgs}" "" ${ARGN})

	#-------------------------------------------------
	# try system-provided package/target first (quiet)
	find_package(${NAME} QUIET)

	if(TARGET ${INTERFACE_TARGET} OR ${NAME}_FOUND)
		message(STATUS "Simple_Fetch_Populate(${NAME}): already available - skipping populate.")
		return()
	endif()

	include(FetchContent)

	#--------------------------------------------
	# normalize repo to full git url if necessary
	if(NOT REPO MATCHES "^[hH][tT][tT][pP][sS]?://")
		set(_repo_url "https://github.com/${REPO}.git")
	else()
		set(_repo_url "${REPO}")
	endif()

	FetchContent_Declare(
		${NAME}
		GIT_REPOSITORY ${_repo_url}
		GIT_TAG        ${GIT_TAG}
		UPDATE_DISCONNECTED ON
	)

	FetchContent_GetProperties(${NAME})
	if(NOT ${NAME}_POPULATED)
		# Temporarily silence the FetchContent_Populate deprecation by using
		# the policy stack: set CMP0169 to OLD for this scope.
		# This prevents the dev-warning (or error on newer CMake) while
		# keeping policy changes local (PUSH/POP).
		cmake_policy(PUSH)
		if(POLICY CMP0169)
			cmake_policy(SET CMP0169 OLD)
		endif()

		# Populate (deprecated call; we suppressed the policy warning locally)
		FetchContent_Populate(${NAME})

		cmake_policy(POP)
	else()
		message("Could not find ${NAME} as properties")
	endif()
	
	# create imported interface target that exposes include dirs
	if(NOT TARGET ${INTERFACE_TARGET})
		add_library(${INTERFACE_TARGET} INTERFACE IMPORTED)
		# set INTERFACE include directories to the populated source include subdir
		set(_incdir "${${NAME}_SOURCE_DIR}/include")
		# make it both INTERFACE_INCLUDE_DIRECTORIES and SYSTEM include (optional)
		set_target_properties(${INTERFACE_TARGET} PROPERTIES
			INTERFACE_INCLUDE_DIRECTORIES "${_incdir}"
			INTERFACE_SYSTEM_INCLUDE_DIRECTORIES "${_incdir}"
		)
		message(STATUS "Simple_Fetch_Populate(${NAME}): created ${INTERFACE_TARGET} -> ${_incdir}")
	else()
		message(STATUS "Simple_Fetch_Populate(${NAME}): interface target ${INTERFACE_TARGET} already exists.")
	endif()
endfunction()