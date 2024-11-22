
resource "azurerm_resource_group" "grupo" {
  name     = "TesteVPN"
  location = "East US"
}



resource "azurerm_virtual_network" "VNET-AKS" {
  name                = "VNET-AKS"
  address_space       = ["10.0.0.0/16", "172.16.0.0/16"]
  location            = "East US"
  resource_group_name = azurerm_resource_group.grupo.name
}

resource "azurerm_subnet" "public1" {
  name                 = "SubredePub"
  resource_group_name  = azurerm_resource_group.grupo.name
  virtual_network_name = azurerm_virtual_network.VNET-AKS.name
  address_prefixes     = ["172.16.1.0/24"]

}

resource "azurerm_subnet" "gateway_subnet" {
  name                 = "GatewaySubnet"
  resource_group_name  = azurerm_resource_group.grupo.name
  virtual_network_name = azurerm_virtual_network.VNET-AKS.name
  address_prefixes     = ["172.16.0.0/27"]
}


# Criação do IP público estático para o VPN Gateway
resource "azurerm_public_ip" "vpn_gateway_ip" {
  name                = "vpn-gateway-ip"
  location            = azurerm_resource_group.grupo.location # Escolha a região adequada
  resource_group_name = azurerm_resource_group.grupo.name     # Nome do seu grupo de recursos
  allocation_method   = "Static"
  sku                 = "Standard" # Necessário para VPN Gateway
}

# Criação do Gateway de Rede Virtual (VPN Gateway)
resource "azurerm_virtual_network_gateway" "vpn_gateway" {
  name                = "VPN-VPG"
  location            = "East US"                         # Escolha a região adequada
  resource_group_name = azurerm_resource_group.grupo.name # Nome do seu grupo de recursos
  type                = "Vpn"                             # Tipo de Gateway: VPN
  sku                 = "VpnGw1"                          # SKU do Gateway: VpnGw1
  active_active       = false
  enable_bgp          = false
  ip_configuration {
    name                          = "VPN-Gateway-IP-Config"
    public_ip_address_id          = azurerm_public_ip.vpn_gateway_ip.id
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.gateway_subnet.id
  }
}

resource "azurerm_network_security_group" "sg" {
  name                = "GrupoLinux"
  location            = azurerm_resource_group.grupo.location
  resource_group_name = azurerm_resource_group.grupo.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "HTTP"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
<<<<<<< HEAD
  
  security_rule {
    name                       = "ICMP"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_subnet_network_security_group_association" "public1_nsg_association" {
  subnet_id                 = azurerm_subnet.public1.id
  network_security_group_id = azurerm_network_security_group.sg.id

=======
}

resource "azurerm_subnet_network_security_group_association" "public1_nsg_association" {
  subnet_id                 = azurerm_subnet.public1.id
  network_security_group_id = azurerm_network_security_group.sg.id

>>>>>>> d5b83f594376b3c6d97c07da65995aabbb2a1abd
}

resource "azurerm_route_table" "Rota_AWS" {
  name                = "tabela_vpn"
  location            = azurerm_resource_group.grupo.location
  resource_group_name = azurerm_resource_group.grupo.name

  route {
    name           = "route1"
    address_prefix = "192.168.1.0/24"
    next_hop_type  = "VirtualNetworkGateway"
  }
}

resource "azurerm_subnet_route_table_association" "Associacao_tabela" {
  subnet_id      = azurerm_subnet.public1.id
  route_table_id = azurerm_route_table.Rota_AWS.id
}

resource "azurerm_local_network_gateway" "GTW-LOCAL01" {
  name                = "GTW-LOCAL01"
  location            = azurerm_resource_group.grupo.location
  resource_group_name = azurerm_resource_group.grupo.name

  gateway_address = aws_vpn_connection.vpn_connection.tunnel1_address
  address_space = [
    aws_subnet.vpn_subnet.cidr_block
  ]
}

resource "azurerm_local_network_gateway" "GTW-LOCAL02" {
  name                = "GTW-LOCAL02"
  location            = azurerm_resource_group.grupo.location
  resource_group_name = azurerm_resource_group.grupo.name

  gateway_address = aws_vpn_connection.vpn_connection.tunnel2_address
  address_space = [
    aws_subnet.vpn_subnet.cidr_block
  ]
}

resource "azurerm_virtual_network_gateway_connection" "CONEXAO-01" {
  name                       = "CONEXAO-01"
  location                   = azurerm_resource_group.grupo.location
  resource_group_name        = azurerm_resource_group.grupo.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.GTW-LOCAL01.id
  # AWS VPN Connection secret shared key
  shared_key = aws_vpn_connection.vpn_connection.tunnel1_preshared_key
}


resource "azurerm_virtual_network_gateway_connection" "CONEXAO-02" {
  name                       = "CONEXAO-02"
  location                   = azurerm_resource_group.grupo.location
  resource_group_name        = azurerm_resource_group.grupo.name
  type                       = "IPsec"
  virtual_network_gateway_id = azurerm_virtual_network_gateway.vpn_gateway.id
  local_network_gateway_id   = azurerm_local_network_gateway.GTW-LOCAL02.id
  # AWS VPN Connection secret shared key
  shared_key = aws_vpn_connection.vpn_connection.tunnel2_preshared_key
<<<<<<< HEAD
}


resource "azurerm_network_interface" "zabbix_server" {
  name                = "example-nic"
  location            = azurerm_resource_group.grupo.location
  resource_group_name = azurerm_resource_group.grupo.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.public1.id
    private_ip_address_allocation = "Dynamic"
  }
}
# O provisionador fica aqui dentro, o que significa que ele só vai rodar após a VM ser criada
resource "azurerm_linux_virtual_machine" "zabbix_server" {
  name                  = "ZabbixServer"
  resource_group_name   = azurerm_resource_group.grupo.name
  location              = azurerm_resource_group.grupo.location
  size                  = "Standard_B2ms" # Tamanho adequado para Zabbix
  admin_username        = "azureuser"
  admin_password        = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.zabbix_server.id]

  os_disk {
    name              = "zabbix-os-disk"
    caching           = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "22.04-LTS"
    version   = "latest"
  }
}


resource "azurerm_linux_virtual_machine_extension" "duahsduihwui" {
  name                      = "customScript"
  virtual_machine_id        = azurerm_linux_virtual_machine.zabbix_server.id
  publisher                  = "Microsoft.Azure.Extensions"
  type                       = "CustomScript"
  type_handler_version      = "2.1"
  settings = <<-SETTINGS
    {
      "scriptFile": "./script_Azure.sh"
    }
  SETTINGS

  depends_on = [
    azurerm_linux_virtual_machine.zabbix_server
  ]
}


=======
}
>>>>>>> d5b83f594376b3c6d97c07da65995aabbb2a1abd
