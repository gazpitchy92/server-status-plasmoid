aaaaaaaaaaaaaaaaaaaa# Server Status Plasmoid

A KDE Plasma 6 widget that displays a list of servers and their current status.  
Supports **Ping** and **HTTP/S** checks for real-time monitoring directly from your desktop.

![Server Status Plasmoid](https://i.postimg.cc/65Ch96J4/server-full.png)

---

## Features
- Display multiple servers in a clean, responsive layout  
- Supports Ping and HTTP/S checks  
- Color-coded status indicators for quick overview  
- Configurable refresh intervals  

---

## Installation

```bash
git clone https://github.com/gazpitchy92/server-status-plasmoid.git
cd server-status-plasmoid
kpackagetool6 --type Plasma/Applet -i ./
