# Add executable targets
########################
ADD_EXECUTABLE(test_click_write_bargraph test_click_write_bargraph.c)

# Add install targets
######################
FILE(GLOB SCRIPTS *.sh)
INSTALL(FILES ${SCRIPTS} DESTINATION /usr/bin/board_test
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ)
INSTALL(TARGETS test_click_write_bargraph
        RUNTIME DESTINATION /usr/bin/board_test)
