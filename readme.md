# Server Status Plasmoid

A KDE Plasma 6 widget that displays a list of servers and their current status.  
Supports **Ping**, **DNS**, and **HTTP/S** checks for real-time monitoring directly from your desktop.

![Server Status Plasmoid](https://i.postimg.cc/FFB3VgTp/server.png)

---

## Features
- Display multiple servers in a clean, responsive layout  
- Supports Ping, DNS, and HTTP/S checks  
- Color-coded status indicators for quick overview  
- Configurable refresh intervals  
- Lightweight and built with Plasma 6 compatibility in mind  

---

## Installation

```bash
git clone https://github.com/gazpitchy92/server-status-plasmoid.git
cd server-status-plasmoid
kpackagetool6 --type Plasma/Applet -i ./