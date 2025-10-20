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
                
                Kirigami.Heading {
                    text: "Server Monitor"
                    level: 3
                }
                
                Item { Layout.fillWidth: true }
                
                QQC2.Button {
                    icon.name: "view-refresh"
                    flat: true
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
                                
                                Text {
                                    text: modelData.ip
                                    font.pixelSize: 12
                                    color: Kirigami.Theme.disabledTextColor
                                    Layout.fillWidth: true
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
            var exitCode = data["exit code"]
            var parts = source.split(" ")
            var serverIp = parts[parts.length - 1] // Get last element (the IP)
            
            // Find and update the server with this IP
            var newServers = servers.slice()
            var found = false
            
            for (var i = 0; i < newServers.length; i++) {
                if (newServers[i].ip === serverIp) {
                    newServers[i].status = (exitCode === 0) ? "UP" : "DOWN"
                    found = true
                    break
                }
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
        try {
            if (configServerList && configServerList.length > 0) {
                var configServers = JSON.parse(configServerList)
                var newServers = []
                
                for (var i = 0; i < configServers.length; i++) {
                    newServers.push({
                        name: configServers[i].name,
                        ip: configServers[i].ip,
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
    
    function checkServer(ip) {
        executable.connectSource("ping -c 1 -W 1 " + ip)
    }
    
    function checkAllServers() {
        for (var i = 0; i < servers.length; i++) {
            checkServer(servers[i].ip)
        }
    }
    
    Component.onCompleted: {
        loadServers()
    }
}
