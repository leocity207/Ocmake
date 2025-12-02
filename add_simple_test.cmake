# Usage:
#   Add_Simple_Googletest_Target(<target-name> <lib1> <lib2> ...)
#
# Examples:
#   Add_Simple_Googletest_Target(configuration_test MyProj::configuration RapidJSON::rapidjson)
function(Add_Simple_Googletest_Target TARGET_NAME)

	#----------------------------------
	# Fetch googletest if not yet found
	find_package(GoogleTest QUIET)
	if (NOT GoogleTest_FOUND AND NOT TARGET GoogleTest)
		include(FetchContent)

		FetchContent_Declare(
			googletest
			GIT_REPOSITORY https://github.com/google/googletest.git
			GIT_TAG v1.17.0
		)

		include(GoogleTest)

		set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

		FetchContent_MakeAvailable(googletest)
	endif()

	#-------------------------------------
	# Get the source of the current folder
	file(GLOB TEST_SRC CONFIGURE_DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp")
	if(NOT TEST_SRC)
		message(FATAL_ERROR "Add_Simple_Googletest_Target(${TARGET_NAME}): no sources found inside \"${CMAKE_CURRENT_SOURCE_DIR}\"")
	endif()

	#-------------------
	# Add test eecutable
	add_executable(${TARGET_NAME} ${TEST_SRC})

	#-----------------------
	# Add include dirrectory
	target_include_directories(${TARGET_NAME}
		PRIVATE
			$<BUILD_INTERFACE:${PROJECT_SOURCE_DIR}>
			$<INSTALL_INTERFACE:include>
	)

	#---------------
	# Link libraries
	target_link_libraries(${TARGET_NAME} PRIVATE GTest::gtest_main ${ARGN})

	gtest_discover_tests(${TARGET_NAME})
endfunction()