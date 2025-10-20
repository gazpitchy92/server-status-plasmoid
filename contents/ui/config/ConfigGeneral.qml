import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kcmutils as KCM

KCM.SimpleKCM {
    id: configRoot
    
    property alias cfg_serverList: serverListField.text
    property alias cfg_pingInterval: pingIntervalSpinBox.value
    
    property var servers: []
    
    ColumnLayout {
        spacing: Kirigami.Units.largeSpacing
        
        // Update Interval Section
        Kirigami.FormLayout {
            QQC2.SpinBox {
                id: pingIntervalSpinBox
                from: 1
                to: 60
                value: 5
                Kirigami.FormData.label: "Update Interval (seconds):"
            }
        }
        
        // Servers Section
        QQC2.GroupBox {
            title: "Servers"
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: Kirigami.Units.smallSpacing
                
                // Add server section at the top
                RowLayout {
                    Layout.fillWidth: true
                    spacing: Kirigami.Units.smallSpacing
                    
                    QQC2.TextField {
                        id: newServerName
                        Layout.fillWidth: true
                        placeholderText: "Server Name (e.g., Web Server)"
                    }
                    
                    QQC2.ComboBox {
                        id: newServerMethod
                        Layout.preferredWidth: 100
                        model: ["Ping", "HTTP/S"]
                        currentIndex: 0
                    }
                    
                    QQC2.TextField {
                        id: newServerAddress
                        Layout.fillWidth: true
                        placeholderText: newServerMethod.currentText === "Ping" ? 
                                       "IP Address (e.g., 192.168.1.1)" : 
                                       "URL (e.g., https://example.com)"
                    }
                    
                    QQC2.Button {
                        text: "Add Server"
                        icon.name: "list-add"
                        enabled: newServerName.text.length > 0 && newServerAddress.text.length > 0
                        onClicked: {
                            addServer(newServerName.text, newServerMethod.currentText, newServerAddress.text)
                            newServerName.text = ""
                            newServerAddress.text = ""
                            newServerMethod.currentIndex = 0
                        }
                    }
                }
                
                QQC2.Label {
                    text: "Configured Servers:"
                    font.bold: true
                    visible: servers.length > 0
                }
                
                // Server list
                QQC2.ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 150
                    
                    ListView {
                        id: serverListView
                        model: servers
                        spacing: Kirigami.Units.smallSpacing
                        clip: true
                        
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 50
                            color: Kirigami.Theme.backgroundColor
                            border.color: Kirigami.Theme.disabledTextColor
                            border.width: 1
                            radius: 4
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing
                                spacing: Kirigami.Units.largeSpacing
                                
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    QQC2.Label {
                                        text: modelData.name
                                        font.bold: true
                                    }
                                    
                                    QQC2.Label {
                                        text: "[" + modelData.method + "] " + modelData.address
                                        font.pixelSize: 11
                                        opacity: 0.7
                                    }
                                }
                                
                                Item {
                                    Layout.fillWidth: true
                                }
                                
                                QQC2.Button {
                                    icon.name: "delete"
                                    text: "Remove"
                                    onClicked: removeServer(index)
                                }
                            }
                        }
                    }
                }
                
                QQC2.Label {
                    text: "No servers configured yet. Add one above."
                    opacity: 0.7
                    visible: servers.length === 0
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        
        // Hidden field to store the actual data
        QQC2.TextField {
            id: serverListField
            visible: false
        }
    }
    
    Component.onCompleted: {
        loadServers()
    }
    
    function loadServers() {
        try {
            if (cfg_serverList && cfg_serverList.length > 0) {
                var parsed = JSON.parse(cfg_serverList)
                // Handle old format (ip) and new format (address)
                var migratedServers = []
                for (var i = 0; i < parsed.length; i++) {
                    var server = parsed[i]
                    migratedServers.push({
                        name: server.name,
                        method: server.method || "Ping",
                        address: server.address || server.ip || ""
                    })
                }
                servers = migratedServers
            } else {
                servers = []
            }
        } catch (e) {
            console.error("Error loading servers:", e)
            servers = []
        }
    }
    
    function saveServers() {
        serverListField.text = JSON.stringify(servers)
    }
    
    function addServer(name, method, address) {
        var newServers = servers.slice()
        newServers.push({
            name: name,
            method: method,
            address: address
        })
        servers = newServers
        saveServers()
    }
    
    function removeServer(index) {
        var newServers = servers.slice()
        newServers.splice(index, 1)
        servers = newServers
        saveServers()
    }
}