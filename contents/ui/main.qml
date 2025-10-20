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
    
    // Store server list with status
    property var servers: []
    
    // Read configuration
    property string configServerList: Plasmoid.configuration.serverList
    property int pingInterval: Plasmoid.configuration.pingInterval
    property bool showTitle: Plasmoid.configuration.showTitle
    property bool showRefreshButton: Plasmoid.configuration.showRefreshButton
    
    // Compact representation (shows count)
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
    
    // Full representation (main UI)
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
                    spacing: Kirigami.Units.smallSpacing
                    clip: true
                    
                    delegate: Rectangle {
                        width: serverListView.width
                        height: 60
                        color: Kirigami.Theme.backgroundColor
                        border.color: Kirigami.Theme.disabledTextColor
                        border.width: 1
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
                                color: modelData.status === "UP" ? "#4caf50" : 
                                       modelData.status === "DOWN" ? "#f44336" : 
                                       "#ff9800"
                                Layout.alignment: Qt.AlignVCenter
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
                            
                            // Status text with fixed width
                            Text {
                                text: modelData.status
                                font.bold: true
                                font.pixelSize: 14
                                color: modelData.status === "UP" ? "#4caf50" : 
                                       modelData.status === "DOWN" ? "#f44336" : 
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
    
    // Ping timer - checks all servers at configured interval
    Timer {
        id: pingTimer
        interval: pingInterval * 1000
        running: true
        repeat: true
        onTriggered: checkAllServers()
    }
    
    // DataSource for running ping commands
    P5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: function(source, data) {
            console.log("onNewData - source:", source)
            console.log("onNewData - exit code:", data["exit code"])
            console.log("onNewData - stdout:", data["stdout"])
            
            var exitCode = data["exit code"]
            
            // Determine if this is a ping or curl command and extract the identifier
            var serverIdentifier = ""
            
            if (source.startsWith("ping")) {
                var parts = source.split(" ")
                serverIdentifier = parts[parts.length - 1] // Get IP address
                console.log("Ping command, extracted IP:", serverIdentifier)
            } else if (source.startsWith("curl")) {
                // Extract URL from: curl -s -o /dev/null -w "%{http_code}" -m 5 URL
                var urlMatch = source.match(/curl.*["']([^"']+)["']/)
                if (urlMatch) {
                    serverIdentifier = urlMatch[1]
                } else {
                    // Fallback: get last argument
                    var curlParts = source.split(" ")
                    serverIdentifier = curlParts[curlParts.length - 1]
                }
                console.log("Curl command, extracted URL:", serverIdentifier)
            }
            
            console.log("Looking for server with address:", serverIdentifier)
            console.log("Current servers:", JSON.stringify(servers))
            
            // Find and update the server with this address
            var newServers = servers.slice()
            var found = false
            
            for (var i = 0; i < newServers.length; i++) {
                console.log("Checking server", i, "address:", newServers[i].address)
                if (newServers[i].address === serverIdentifier) {
                    // For HTTP/S, check both exit code and response
                    if (newServers[i].method === "HTTP/S") {
                        var stdout = data["stdout"] || ""
                        var httpCode = parseInt(stdout.trim())
                        // Success if exit code is 0 and HTTP status is 2xx or 3xx
                        newServers[i].status = (exitCode === 0 && httpCode >= 200 && httpCode < 400) ? "UP" : "DOWN"
                    } else {
                        // For Ping, just check exit code
                        newServers[i].status = (exitCode === 0) ? "UP" : "DOWN"
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
            
            // Disconnect the source after getting data
            executable.disconnectSource(source)
        }
    }
    
    // Watch for configuration changes
    onConfigServerListChanged: {
        // Disconnect all existing sources
        var sources = executable.connectedSources
        for (var i = 0; i < sources.length; i++) {
            executable.disconnectSource(sources[i])
        }
        
        loadServers()
    }
    
    onPingIntervalChanged: {
        pingTimer.interval = pingInterval * 1000
    }
    
    // Functions
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
                    // Handle both old format (ip) and new format (address)
                    var address = server.address || server.ip || ""
                    var method = server.method || "Ping"
                    
                    console.log("Server name:", server.name, "method:", method, "address:", address)
                    
                    newServers.push({
                        name: server.name,
                        method: method,
                        address: address,
                        status: "CHECKING..."
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
    
    function checkServer(method, address) {
        console.log("checkServer called with method:", method, "address:", address)
        if (method === "Ping") {
            var cmd = "ping -c 1 -W 1 " + address
            console.log("Executing:", cmd)
            executable.connectSource(cmd)
        } else if (method === "HTTP/S") {
            var curlCmd = "curl -s -o /dev/null -w \"%{http_code}\" -m 5 '" + address + "'"
            console.log("Executing:", curlCmd)
            executable.connectSource(curlCmd)
        }
    }
    
    function checkAllServers() {
        for (var i = 0; i < servers.length; i++) {
            checkServer(servers[i].method, servers[i].address)
        }
    }
    
    Component.onCompleted: {
        loadServers()
    }
}