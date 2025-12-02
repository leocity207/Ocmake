# cmake/SimpleFetch.cmake
#
# Usage:
#   Simple_Fetch_Repository(<Name> <RepoOrOwner/Repo> <GitTag> [DISABLE_OPTIONS opt1;opt2;...])
#
# Examples:
#   Simple_Fetch_Repository(OConfigurator leocity207/OConfigurator V0.0.3)
#   Simple_Fetch_Repository(MyLib https://github.com/org/MyLib.git v1.2.3 DISABLE_OPTIONS BUILD_TESTS;BUILD_DOC;SOME_FLAG)
#
function(Simple_Fetch_Repository NAME REPO GIT_TAG)

	find_package(${NAME} QUIET)

	if(TARGET ${NAME} OR ${NAME}_FOUND)
		message(STATUS "Simple_Fetch_Repository(${NAME}): already available - skipping populate.")
		return()
	endif()

	#---------------------------------------------
	# Default options used in Octoliiners projects
	set(options_default "BUILD_TESTS;BUILD_DOC")
	set(opts "${options_default}")

	#------------------------------------------------------
	# Parse optional arg DISABLE_OPTIONS if present in ARGN
	foreach(_arg IN LISTS ARGN)
		if(_arg MATCHES "^DISABLE_OPTIONS$")
			list(GET ARGN 0 _dummy)
			list(FIND ARGN "DISABLE_OPTIONS" _pos)
			math(EXPR _next_pos "${_pos} + 1")
			if(_next_pos LESS "${ARGC}")
				list(GET ARGN ${_next_pos} _optlist)
				set(opts "${_optlist}")
			endif()
			break()
		endif()
	endforeach()

	#--------------------------------------------------------------
	# Try find_package (quiet) to see if system already provides it
	find_package(${NAME} QUIET)

	#--------------------------------------------------------
	# If REPO is in short form owner/repo, convert to full URL
	if(NOT REPO MATCHES "^[hH][tT][tT][pP][sS]?://")
		set(_repo_url "https://github.com/${REPO}.git")
	else()
		set(_repo_url "${REPO}")
	endif()

	#-------------------------------------------------------
	# check whether package already present or target exists
	# Note: if ${NAME}_FOUND is undefined it expands to empty (treated as FALSE),
	# so the condition below behaves correctly: we fetch only if not found and no target.
	include(FetchContent)

	#-----------
	# Save State
	string(REPLACE ";" " " _opt_list "${opts}")
	set(_saved_vars "")
	foreach(opt IN LISTS opts)
		if(DEFINED ${opt})
			# stocker la valeur actuelle
			set(_val "${${opt}}")
			set(_saved_vars "${_saved_vars};${opt}=${_val}")
		else()
			set(_saved_vars "${_saved_vars};${opt}=__UNSET__")
		endif()
		set(${opt} OFF CACHE BOOL "Temporarily disabled for FetchContent" FORCE)
	endforeach()

	#---------------------
	# Do the fetch content
	if(GIT_TAG)
		FetchContent_Declare(
			${NAME}
			GIT_REPOSITORY ${_repo_url}
			GIT_TAG ${GIT_TAG}
		)
	else()
		FetchContent_Declare(
			${NAME}
			GIT_REPOSITORY ${_repo_url}
		)
	endif()

	FetchContent_MakeAvailable(${NAME})

	#--------------------------
	# Restore state of variable
	foreach(_entry IN LISTS _saved_vars)
		if(_entry STREQUAL "") 
			continue()
		endif()
		string(REPLACE "=" ";" _pair "${_entry}")
		list(GET _pair 0 _optname)
		list(GET _pair 1 _optval)
		if(_optval STREQUAL "__UNSET__")
			set(${_optname} "" CACHE STRING "Restored" FORCE)
		else()
			set(${_optname} "${_optval}" CACHE STRING "Restored" FORCE)
		endif()
	endforeach()

	unset(_saved_vars)
	unset(_repo_url)
	unset(_opt_list)
endfunction()
