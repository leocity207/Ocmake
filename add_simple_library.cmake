# Usage:
#   Add_Simple_Library(<name> <TYPE> [link_lib1 link_lib2 ...])
#
# Example:
#   Add_Simple_Library(dcel STATIC ${PROJECT_NAME}::io)
function(Add_Simple_Library TARGET_NAME TYPE)

	#------------------
	# Set up and verify
	if(NOT TYPE)
		set(TYPE STATIC)
	endif()
	if(TARGET ${TARGET_NAME})
		message(FATAL_ERROR "Add_Simple_Library: target '${TARGET_NAME}' already exists")
	endif()


	#--------
	# Get CPP
	file(GLOB TEST_SRC CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")

	#--------------------------------------------------------------------------
	# Create the library (TYPE should be STATIC|SHARED|MODULE|OBJECT|INTERFACE)
	add_library(${TARGET_NAME} ${TYPE} ${TEST_SRC})

	#-------------
	# Add includes
	get_target_property(target_type ${TARGET_NAME} TYPE)
	if(target_type STREQUAL "INTERFACE_LIBRARY")
		target_include_directories(${TARGET_NAME}
			INTERFACE
				$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
				$<INSTALL_INTERFACE:include>
		)
	else()
		target_include_directories(${TARGET_NAME}
			PUBLIC
				$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}/include>
				$<INSTALL_INTERFACE:include>
		)
	endif()

	#----------
	# Link libs
	set(libraries ${ARGN})
	if(libraries)
		target_link_libraries(${TARGET_NAME} PUBLIC ${libraries})
	endif()

	set(alias_name "${PROJECT_NAME}::${TARGET_NAME}")
	if(NOT TARGET ${alias_name})
		add_library(${alias_name} ALIAS ${TARGET_NAME})
	else()
		message(WARNING "Add_Simple_Library: alias '${alias_name}' already exists")
	endif()

endfunction()
