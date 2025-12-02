# Usage:
#   Add_Project_Documentation(<DOC_DIR_SRC>)
#
# Example:
#   Add_Project_Documentation(dcel documentation/src)
function(Add_Project_Documentation DOC_DIR_SRC)
	include(FetchContent)

	#-------------------
	# fetch cmake-sphinx
	find_package(cmake_sphinx QUIET)
	if (NOT cmake_sphinx_FOUND)
		FetchContent_Declare(
		cmake_sphinx
		GIT_REPOSITORY https://github.com/k0ekk0ek/cmake-sphinx.git
		)

		#-----------------------
		# Populate  if necessary
		FetchContent_GetProperties(cmake_sphinx)
		if(NOT cmake_sphinx_POPULATED)
			message(STATUS "Downloading cmake-sphinx from ${cmake_sphinx_GIT_REPOSITORY}")
			cmake_policy(PUSH)
			if(POLICY CMP0169)
				cmake_policy(SET CMP0169 OLD)
			endif()
			FetchContent_Populate(cmake_sphinx)
			cmake_policy(POP)
		endif()
	endif()

	#-------------------------
	# Add cmake module to path
	if(DEFINED cmake_sphinx_SOURCE_DIR AND EXISTS "${cmake_sphinx_SOURCE_DIR}/cmake/Modules")
		list(APPEND CMAKE_MODULE_PATH "${cmake_sphinx_SOURCE_DIR}/cmake/Modules")
		message(STATUS "Appended cmake-sphinx modules: ${cmake_sphinx_SOURCE_DIR}/cmake/Modules")
	else()
		message(WARNING "cmake-sphinx was fetched but '${cmake_sphinx_SOURCE_DIR}/cmake/Modules' not found.")
	endif()

	find_package(Doxygen)
	find_package(Sphinx)

	if(Doxygen_FOUND AND Sphinx_FOUND)
		find_package(Sphinx REQUIRED breathe)

		# Config Doxygen minimal
		set(DOXYGEN_GENERATE_HTML NO)
		set(DOXYGEN_GENERATE_XML YES)
		doxygen_add_docs(doxygen
			${PROJECT_SOURCE_DIR}/include
			COMMENT "Generate man pages"
		)

		sphinx_add_docs(
			${PROJECT_NAME}_Documentation
			BREATHE_PROJECTS doxygen
			BUILDER html
			SOURCE_DIRECTORY ${DOC_DIR_SRC}
			CONFIG_DIRECTORY ${DOC_DIR_SRC}
		)

		message(STATUS "Documentation target '${PROJECT_NAME}' created.")
	else()
		message(WARNING "Cannot build documentation: Doxygen, Sphinx, or breathe not found.")
	endif()
endfunction()
