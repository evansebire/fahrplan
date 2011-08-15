import QtQuick 1.1
import com.meego 1.0
import com.nokia.extras 1.0
import "components" as MyComponents
import Fahrplan 1.0 as Fahrplan

Page {
    id: mainPage

    tools: mainToolbar

    Item {
        id: titleBar

        width: parent.width
        height: 70

        Rectangle {
            anchors.fill: parent
            color: "LightGrey"
        }

        Rectangle {
            anchors.fill: parent
            color: "Grey"
            visible: mouseArea.pressed
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            enabled: parent.enabled
            onClicked: {
                console.log("TODO Backend parser switch");
            }
        }

        Label {
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
                top: parent.top
                topMargin: 20
            }
            font.bold: true;
            font.pixelSize: 32

            text: fahrplanBackend.parserName
        }

        Image {
            id: icon

            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            height: sourceSize.height
            width: sourceSize.width
            source: "image://theme/meegotouch-combobox-indicator"
        }
    }

    ButtonColumn {
        id: buttons

        anchors {
            topMargin: 20
            top: titleBar.bottom
            leftMargin: 10
            rightMargin: 10
            left: parent.left
        }

        width: parent.width - 20
        exclusive: false

        MyComponents.SubTitleButton {
            id: departureButton
            titleText: "Departure Station"
            subTitleText: "please select"
            width: parent.width
            onClicked: {
                pageStack.push(departureStationSelect)
            }
        }
        MyComponents.SubTitleButton {
            id: arrivalButton
            titleText: "Arrival Station"
            subTitleText: "please select"
            width: parent.width
            onClicked: {
                pageStack.push(arrivalStationSelect)
            }
        }
        MyComponents.SubTitleButton {
            id: datePickerButton
            titleText: "Date"
            subTitleText: "please select"
            width: parent.width
            onClicked: {
                datePicker.open();
            }
        }
        MyComponents.SubTitleButton {
            id: timePickerButton
            titleText: "Time"
            subTitleText: "please select"
            width: parent.width
            onClicked: {
                timePicker.open();
            }
        }
    }

    Button {
        id: startSearch
        text: "Start search"
        anchors {
            top: buttons.bottom
            topMargin: 10
            horizontalCenter: parent.horizontalCenter
        }

        onClicked: {
            pageStack.push(loadingPage)
            var selDate = new Date(datePicker.year, datePicker.month - 1, datePicker.day);
            var selTime = new Date(1970, 2, 1, timePicker.hour, timePicker.minute, timePicker.second);
            fahrplanBackend.parser.searchJourney(departureButton.subTitleText, arrivalButton.subTitleText, "", selDate, selTime, 0, 0);
        }
    }

    MyComponents.StationSelect {
        id: departureStationSelect

        onStationSelected: {
            departureButton.subTitleText = name;
            pageStack.pop();
        }
    }

    MyComponents.StationSelect {
        id: arrivalStationSelect

        onStationSelected: {
            arrivalButton.subTitleText = name;
            pageStack.pop();
        }
    }

    JourneyDetailsResultsPage {
        id: detailsResultsPage
    }

    JourneyResultsPage {
        id: resultsPage
    }

    LoadingPage {
        id: loadingPage
    }

    DatePickerDialog {
        id: datePicker
        titleText: "Date"
        acceptButtonText: "Ok"
        rejectButtonText: "Cancel"
        onAccepted: {
            var selDate = new Date(datePicker.year, datePicker.month - 1, datePicker.day);
            datePickerButton.subTitleText = Qt.formatDate(selDate);
        }
        Component.onCompleted: {
            var d = new Date();
            datePicker.year = d.getFullYear();
            datePicker.month = d.getMonth() + 1; // month is 0 based in Date()
            datePicker.day = d.getDate();
            datePickerButton.subTitleText = Qt.formatDate(d);
        }
    }

    TimePickerDialog {
        id: timePicker
        titleText: "Time"
        acceptButtonText: "Ok"
        rejectButtonText: "Cancel"
        onAccepted: {
            var selTime = new Date(1970, 2, 1, timePicker.hour, timePicker.minute, timePicker.second);
            timePickerButton.subTitleText = Qt.formatTime(selTime);
        }
        Component.onCompleted: {
            var d = new Date();
            timePicker.hour = d.getHours();
            timePicker.minute = d.getMinutes();
            timePicker.second = d.getSeconds();
            timePickerButton.subTitleText = Qt.formatTime(d);
        }
    }

    ToolBarLayout {
        id: mainToolbar
    }

    InfoBanner{
            id: banner
            objectName: "fahrplanInfoBanner"
            text: ""
            anchors.top: button.bottom
            anchors.topMargin: 10
    }

    Timer {
        id: showResultsTimer
        interval: 800
        running: false
        repeat: false
        onTriggered: {
            pageStack.push(resultsPage);
        }
    }

    Timer {
        id: showDetailsResultsTimer
        interval: 800
        running: false
        repeat: false
        onTriggered: {
            pageStack.push(detailsResultsPage);
        }
    }

    Timer {
        id: hideLoadingTimer
        interval: 800
        running: false
        repeat: false
        onTriggered: {
            pageStack.pop();
        }
    }

    Fahrplan.Backend {
        id: fahrplanBackend
        /*
           An error can occour here, if the result is returned quicker than
           the pagestack is popped so we use a timer here if the pagestack is busy.
         */
        onParserJourneyResult: {
            if (pageStack.busy) {
                showResultsTimer.interval = 800
                hideLoadingTimer.interval = 800
            } else {
                showResultsTimer.interval = 1
                hideLoadingTimer.interval = 1
            }
            if (result.count > 0) {
                showResultsTimer.start();
            } else {
                hideLoadingTimer.start();
                banner.text = "No results found";
                banner.show();
            }
        }
        onParserJourneyDetailsResult: {
            if (pageStack.busy) {
                showDetailsResultsTimer.interval = 800
                hideLoadingTimer.interval = 800
            } else {
                showDetailsResultsTimer.interval = 1
                hideLoadingTimer.interval = 1
            }
            if (result.count > 0) {
                showDetailsResultsTimer.start();
            } else {
                hideLoadingTimer.start();
                banner.text = "No results found";
                banner.show();
            }
        }
        onParserErrorOccured: {
            if (pageStack.busy) {
                hideLoadingTimer.interval = 800
            } else {
                hideLoadingTimer.interval = 1
            }
            hideLoadingTimer.start();
            banner.text = msg;
            banner.show();
        }
    }
}