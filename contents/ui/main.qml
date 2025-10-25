import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami as Kirigami
import org.kde.plasma.plasma5support as P5Support

PlasmoidItem {
    id: root
    
    width: Kirigami.Units.gridUnit * 15
    height: Kirigami.Units.gridUnit * 10
    
    // Servers array
    property var servers: []
    // Configs
    property string configServerList: Plasmoid.configuration.serverList
    property int pingInterval: Plasmoid.configuration.pingInterval
    property bool showTitle: Plasmoid.configuration.showTitle
    property bool showRefreshButton: Plasmoid.configuration.showRefreshButton
    
    // Compact UI
    compactRepresentation: Item {
        Column {
            anchors.centerIn: parent
            spacing: 4
            Kirigami.Icon {
                source: "network-server"
                width: Kirigami.Units.iconSizes.medium
                height: width
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: servers.length + " servers"
                font.pixelSize: 10
                color: Kirigami.Theme.textColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
    
    // Main UI
    fullRepresentation: Item {
        width: Kirigami.Units.gridUnit * 25
        height: Kirigami.Units.gridUnit * 20
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Kirigami.Units.smallSpacing
            spacing: Kirigami.Units.smallSpacing
            
            // Header
            RowLayout {
                Layout.fillWidth: true
                visible: showTitle || showRefreshButton
                Kirigami.Heading {
                    text: "Server Status"
                    level: 3
                    visible: showTitle
                }
                Item { Layout.fillWidth: true }
                QQC2.Button {
                    icon.name: "view-refresh"
                    flat: true
                    visible: showRefreshButton
                    onClicked: checkAllServers()
                    QQC2.ToolTip.text: "Refresh"
                    QQC2.ToolTip.visible: hovered
                }
            }
            
            // Server list
            QQC2.ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: serverListView
                    model: servers
                    spacing: Kirigami.Units.largeSpacing
                    clip: true

                    delegate: Rectangle {
                        width: serverListView.width
                        height: 61
                        color: modelData.status === "⟱ DOWN" ? Qt.darker(Kirigami.Theme.backgroundColor, 1.8) : 
                            modelData.status === "⟷ CHECKING..." ? Qt.darker(Kirigami.Theme.backgroundColor, 1.3) : 
                            Qt.lighter(Kirigami.Theme.backgroundColor, 1.5) 
                        radius: 4

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: Kirigami.Units.largeSpacing
                            spacing: Kirigami.Units.largeSpacing
                    
                            // Status indicator
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: modelData.status === "⟰ UP" ? "#4caf50" : 
                                    modelData.status === "⟱ DOWN"? "#f44336" : 
                                    "#ff9800"
                                Layout.alignment: Qt.AlignVCenter
                                SequentialAnimation on opacity {
                                    running: modelData.status === "⟱ DOWN"
                                    loops: Animation.Infinite
                                    NumberAnimation { 
                                        from: 0.3; 
                                        to: 1.0; 
                                        duration: 1200; 
                                        easing.type: Easing.InOutQuad 
                                    }
                                    NumberAnimation { 
                                        from: 1.0; 
                                        to: 0.3; 
                                        duration: 1200; 
                                        easing.type: Easing.InOutQuad 
                                    }
                                }
                            }
                            
                            // Server info
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 2
                                Text {
                                    text: modelData.name
                                    font.bold: true
                                    font.pixelSize: 14
                                    color: Kirigami.Theme.textColor
                                    Layout.fillWidth: true
                                }
                                RowLayout {
                                    spacing: Kirigami.Units.smallSpacing
                                    
                                    Text {
                                        text: "[" + modelData.method + "]"
                                        font.pixelSize: 10
                                        color: Kirigami.Theme.disabledTextColor
                                    }
                                    Text {
                                        text: modelData.address
                                        font.pixelSize: 12
                                        color: Kirigami.Theme.disabledTextColor
                                        Layout.fillWidth: true
                                    }
                                }
                            }
                            
                            // Status text
                            Text {
                                text: modelData.status
                                font.bold: true
                                font.pixelSize: 14
                                color: modelData.status === "⟰ UP" ? "#4caf50" : 
                                       modelData.status === "⟱ DOWN"? "#f44336" : 
                                       "#ff9800"
                                horizontalAlignment: Text.AlignRight
                                Layout.preferredWidth: 80
                                Layout.alignment: Qt.AlignVCenter
                            }

                        }
                    }
                }
            }
            
            // Empty state
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: servers.length === 0
                Column {
                    anchors.centerIn: parent
                    spacing: Kirigami.Units.largeSpacing
                    Kirigami.Icon {
                        source: "network-server"
                        width: Kirigami.Units.iconSizes.huge
                        height: width
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.3
                    }
                    Text {
                        text: "No servers configured"
                        color: Kirigami.Theme.disabledTextColor
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    QQC2.Button {
                        text: "Open Settings"
                        anchors.horizontalCenter: parent.horizontalCenter
                        onClicked: Plasmoid.internalAction("configure").trigger()
                    }
                }
            }
        }
    }
    
    // Update timer
    Timer {
        id: pingTimer
        interval: pingInterval * 1000
        running: true
        repeat: true
        onTriggered: checkAllServers()
    }
    
    // Update status commands
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(source, data) {
            console.log("onNewData - source:", source)
            console.log("onNewData - exit code:", data["exit code"])
            console.log("onNewData - stdout:", data["stdout"])
            var exitCode = data["exit code"]
            var serverIdentifier = ""

            // Check status
            if (source.startsWith("ping")) {
                // PING
                var parts = source.split(" ")
                serverIdentifier = parts[parts.length - 1] // Get IP address
                console.log("Ping command, extracted IP:", serverIdentifier)
            } else if (source.startsWith("curl")) {
                // HTTP Curl
                var urlMatch = source.match(/curl.*["']([^"']+)["']/)
                if (urlMatch) {
                    serverIdentifier = urlMatch[1]
                } else {
                    var curlParts = source.split(" ")
                    serverIdentifier = curlParts[curlParts.length - 1]
                }
                console.log("Curl command, extracted URL:", serverIdentifier)
            }
            console.log("Looking for server with address:", serverIdentifier)
            console.log("Current servers:", JSON.stringify(servers))
            
            // Update the UI with the status 
            var newServers = servers.slice()
            var found = false
            for (var i = 0; i < newServers.length; i++) {
                console.log("Checking server", i, "address:", newServers[i].address)
                if (newServers[i].address === serverIdentifier) {
                    if (newServers[i].method === "HTTP/S") {
                        var stdout = data["stdout"] || ""
                        var httpCode = parseInt(stdout.trim())
                        newServers[i].status = (exitCode === 0 && httpCode >= 200 && httpCode < 400) ? "⟰ UP" : "⟱ DOWN"
                    } else {
                        newServers[i].status = (exitCode === 0) ? "⟰ UP" : "⟱ DOWN"
                    }
                    console.log("Updated server", i, "to status:", newServers[i].status)
                    found = true
                    break
                }
            }

            if (!found) {
                console.log("WARNING: No matching server found for address:", serverIdentifier)
            }
            if (found) {
                servers = newServers
            }
            executable.disconnectSource(source)
        }
    }
    
    // Cleanup UI 
    onConfigServerListChanged: {
        var sources = executable.connectedSources
        for (var i = 0; i < sources.length; i++) {
            executable.disconnectSource(sources[i])
        }
        loadServers()
    }
    
    // Timer
    onPingIntervalChanged: {
        pingTimer.interval = pingInterval * 1000
    }
    
    // Loading config
    function loadServers() {
        console.log("Loading servers from config:", configServerList)
        try {
            if (configServerList && configServerList.length > 0) {
                var configServers = JSON.parse(configServerList)
                console.log("Parsed servers:", JSON.stringify(configServers))
                var newServers = []
                
                for (var i = 0; i < configServers.length; i++) {
                    var server = configServers[i]
                    console.log("Processing server:", JSON.stringify(server))
                    var address = server.address || server.ip || ""
                    var method = server.method || "Ping"
                    console.log("Server name:", server.name, "method:", method, "address:", address)
                    newServers.push({
                        name: server.name,
                        method: method,
                        address: address,
                        status: "⟷ CHECKING..."
                    })
                }
                servers = newServers
                checkAllServers()
            } else {
                servers = []
            }
        } catch (e) {
            console.error("Error loading servers:", e)
            servers = []
        }
    }
    
    // Check server status function
    function checkServer(method, address) {
        console.log("checkServer called with method:", method, "address:", address)
        if (method === "Ping") {
            var cmd = "ping -c 1 -W 1 " + address
            console.log("Executing:", cmd)
            executable.connectSource(cmd)
        } else if (method === "HTTP/S") {
            var curlCmd = "curl -k -s -o /dev/null -w \"%{http_code}\" -m 5 '" + address + "'"
            console.log("Executing:", curlCmd)
            executable.connectSource(curlCmd)
        }
    }
    
    // Trigger full update
    function checkAllServers() {
        for (var i = 0; i < servers.length; i++) {
            checkServer(servers[i].method, servers[i].address)
        }
    }
    
    Component.onCompleted: {
        loadServers()
    }
}