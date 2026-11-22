# ========================================================
# Полный скрипт базовой настройки и защиты MikroTik RouterOS
# ========================================================

# --- ЭТАП 2: Настройка Bridge, LAN и DHCP-сервера ---
/interface bridge add name=bridge_lan
/interface bridge port
add bridge=bridge_lan interface=ether1
add bridge=bridge_lan interface=ether2
add bridge=bridge_lan interface=ether3
add bridge=bridge_lan interface=ether4

/ip address add address=192.168.9.1/24 interface=bridge_lan comment="LAN Gateway"

/ip pool add name=dhcp_pool_lan ranges=192.168.9.11-192.168.9.254
/ip dhcp-server add name=dhcp_lan interface=bridge_lan address-pool=dhcp_pool_lan disabled=no
/ip dhcp-server network add address=192.168.9.0/24 gateway=192.168.9.1 dns-server=192.168.9.1

# --- ЭТАП 3: Настройка WAN (DHCP-клиент) и NAT ---
/ip dhcp-client add interface=ether5 add-default-route=yes disabled=no comment="WAN Provider"
/ip dns set allow-remote-requests=yes

/ip firewall nat add chain=srcnat out-interface=ether5 action=masquerade comment="NAT for LAN"

# --- ЭТАП 4: Базовая защита доступа и Firewall ---
# Смена администратора
/user add name=secadmin group=full password="ChangeMeToStrongPassword123!" address=192.168.9.0/24
/user disable admin

# Отключение небезопасных сервисов и ограничение доступа только из LAN
/ip service disable telnet,ftp,www,api,api-ssl
/ip service set winbox address=192.168.9.0/24
/ip service set ssh address=192.168.9.0/24

# Базовая защита самого роутера (цепочка Input)
/ip firewall filter
add chain=input action=accept connection-state=established,related comment="Allow established & related"
add chain=input action=drop connection-state=invalid comment="Drop invalid packets"
add chain=input action=accept in-interface=bridge_lan comment="Allow access from LAN"
add chain=input action=drop in-interface=ether5 comment="Drop all incoming from WAN"
