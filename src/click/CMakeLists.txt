# Add executable targets
########################
ADD_EXECUTABLE(test_click_write_bargraph test_click_write_bargraph.c)
ADD_EXECUTABLE(test_click_read_thermo3 test_click_read_thermo3.c)

# Add install targets
######################
FILE(GLOB SCRIPTS *.sh)
INSTALL(FILES ${SCRIPTS} DESTINATION /usr/bin/board_test
        PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
        GROUP_EXECUTE GROUP_READ
        WORLD_EXECUTE WORLD_READ)
INSTALL(TARGETS test_click_write_bargraph test_click_read_thermo3
        RUNTIME DESTINATION /usr/bin/board_test)
