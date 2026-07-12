cmake_minimum_required( VERSION 3.15 )
project( Havoc )

##
## cmake sets
##
set( QT_VERSION_MAJOR "" )
set( CMAKE_CXX_STANDARD 20 )
set( CMAKE_CXX_STANDARD_REQUIRED ON )
set( CMAKE_CXX_EXTENSIONS OFF )
set( CMAKE_AUTOMOC ON )
set( CMAKE_AUTORCC ON )
set( CMAKE_AUTOUIC ON )
set( CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpermissive" )
set( REQUIRED_LIBS Core Gui Widgets Network WebSockets Sql )
set( REQUIRED_LIBS_QUALIFIED )
set( APP_ICON_RESOURCE_WINDOWS "data/Havoc.qrc" )
set( CMAKE_RUNTIME_OUTPUT_DIRECTORY .. )
set( CMAKE_INCLUDE_CURRENT_DIR ON )

##
## Ensure 3.10 is used if present.
## If not, modules will not work within the client.
##
set( Python_ADDITIONAL_VERSIONS 3.10 )

##
## import includes and external libraries
##
include_directories( include  )
include_directories( external/spdlog/include )
include_directories( external/json/include )
include_directories( external/toml/include )

##
## find qt packages
##
find_package( QT NAMES Qt6 Qt5 COMPONENTS ${REQUIRED_LIBS} REQUIRED )
find_package( Qt${QT_VERSION_MAJOR} COMPONENTS ${REQUIRED_LIBS} REQUIRED )
set( REQUIRED_LIBS_QUALIFIED Qt${QT_VERSION_MAJOR}::Core Qt${QT_VERSION_MAJOR}::Gui Qt${QT_VERSION_MAJOR}::Widgets Qt${QT_VERSION_MAJOR}::Network Qt${QT_VERSION_MAJOR}::WebSockets Qt${QT_VERSION_MAJOR}::Sql )

##
## python support
##
find_package( Python3 COMPONENTS Interpreter Development REQUIRED )
set( PYTHONLIBS_VERSION_STRING ${Python3_VERSION} )
set( PYTHON_INCLUDE_DIRS ${Python3_INCLUDE_DIRS} )
set( PYTHON_LIBRARIES Python3::Python )
include_directories( ${PYTHON_INCLUDE_DIRS} )
set( HAVOC_INCLUDE

        # Misc
        include/Havoc/Connector.hpp
        include/Havoc/DBManager/DBManager.hpp
        include/Havoc/DemonCmdDispatch.h
        include/Havoc/Packager.hpp
        include/Havoc/Havoc.hpp
        include/Havoc/Service.hpp
        include/Havoc/CmdLine.hpp

        # Python Api
        include/Havoc/PythonApi/PythonApi.h
        include/Havoc/PythonApi/Event.h
        include/Havoc/PythonApi/HavocUi.h
        include/Havoc/PythonApi/PyAgentClass.hpp
        include/Havoc/PythonApi/UI/PyDialogClass.hpp
        include/Havoc/PythonApi/UI/PyLoggerClass.hpp
        include/Havoc/PythonApi/UI/PyTreeClass.hpp
        include/Havoc/PythonApi/UI/PyWidgetClass.hpp

        # Dialogs
        include/UserInterface/Dialogs/Payload.hpp
        include/UserInterface/Dialogs/About.hpp
        include/UserInterface/Dialogs/Connect.hpp
        include/UserInterface/Dialogs/Listener.hpp

        # small widgets
        include/UserInterface/SmallWidgets/EventViewer.hpp
        include/UserInterface/SmallWidgets/EventViewer.hpp

        # widgets
        include/UserInterface/Widgets/Chat.hpp
        include/UserInterface/Widgets/DemonInteracted.h
        include/UserInterface/Widgets/ListenerTable.hpp
        include/UserInterface/Widgets/ProcessList.hpp
        include/UserInterface/Widgets/PythonScript.hpp
        include/UserInterface/Widgets/SessionTable.hpp
        include/UserInterface/Widgets/SessionGraph.hpp
        include/UserInterface/Widgets/TeamserverTabSession.h
        include/UserInterface/Widgets/ScriptManager.h
        include/UserInterface/Widgets/LootWidget.h
        include/UserInterface/Widgets/FileBrowser.hpp
        include/UserInterface/Widgets/Teamserver.hpp
        include/UserInterface/Widgets/Store.hpp

        include/UserInterface/HavocUI.hpp
)

# src for UI
set(
        HAVOC_UI

        src/UserInterface/HavocUi.cc
        src/global.cc

        # Dialogs
        src/UserInterface/Dialogs/About.cc
        src/UserInterface/Dialogs/Connect.cc
        src/UserInterface/Dialogs/Listener.cc
        src/UserInterface/Dialogs/Payload.cc

        # Widgets
        src/UserInterface/Widgets/SessionTable.cc
        src/UserInterface/Widgets/SessionGraph.cc
        src/UserInterface/Widgets/Chat.cc
        src/UserInterface/Widgets/ListenersTable.cc
        src/UserInterface/Widgets/DemonInteracted.cc
        src/UserInterface/Widgets/TeamserverTabSession.cc
        src/UserInterface/Widgets/PythonScript.cc
        src/UserInterface/Widgets/ScriptManager.cc
        src/UserInterface/Widgets/LootWidget.cc
        src/UserInterface/Widgets/FileBrowser.cc
        src/UserInterface/Widgets/Teamserver.cc
        src/UserInterface/Widgets/Store.cc
        src/UserInterface/Widgets/ProcessList.cc

        # SmallWidgets
        src/UserInterface/SmallWidgets/EventViewer.cc
)

set(
        HAVOC_UTIL

        src/Util/ColorText.cpp
        src/Util/Base64.cpp
        src/Util/Base.cpp
)

# src for Havoc
set( HAVOC_SOURCE
        src/Main.cc

        src/Havoc/Packager.cc
        src/Havoc/Connector.cc
        src/Havoc/Service.cc

        src/Havoc/DBManger/DBManager.cc
        src/Havoc/DBManger/Teamserver.cc
        src/Havoc/DBManger/Scripts.cc

        src/Havoc/Demon/ConsoleInput.cc
        src/Havoc/Demon/CommandSend.cc
        src/Havoc/Demon/CommandOutput.cc
        src/Havoc/Demon/Commands.cc

        src/Havoc/PythonApi/PythonApi.cc
        src/Havoc/PythonApi/Havoc.cc
        src/Havoc/PythonApi/HavocUi.cc
        src/Havoc/PythonApi/UI/PyDialogClass.cc
        src/Havoc/PythonApi/UI/PyLoggerClass.cc
        src/Havoc/PythonApi/UI/PyTreeClass.cc
        src/Havoc/PythonApi/UI/PyWidgetClass.cc
        src/Havoc/PythonApi/PyDemonClass.cc
        src/Havoc/PythonApi/Event.cc
        src/Havoc/PythonApi/PyAgentClass.cc

        src/Havoc/Havoc.cc

    ${HAVOC_UI}
)

add_executable( ${PROJECT_NAME} ${HAVOC_INCLUDE} ${HAVOC_SOURCE} ${HAVOC_UTIL} ${APP_ICON_RESOURCE_WINDOWS} data/Havoc.rc )
add_definitions( -DQT_NO_DEBUG_OUTPUT )

target_link_libraries(
    ${PROJECT_NAME}
    ${REQUIRED_LIBS_QUALIFIED}
    ${PYTHON_LIBRARIES}
    # spdlog::spdlog
    # spdlog::spdlog_header_only
)
