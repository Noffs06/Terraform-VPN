
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

# resource "azurerm_network_security_group" "sg" {
#   name                = "GrupoLinux"
#   location            = azurerm_resource_group.grupo.location
#   resource_group_name = azurerm_resource_group.grupo.name

#   security_rule {
#     name                       = "SSH"
#     priority                   = 1001
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "22"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
#   security_rule {
#     name                       = "HTTP"
#     priority                   = 1002
#     direction                  = "Inbound"
#     access                     = "Allow"
#     protocol                   = "Tcp"
#     source_port_range          = "*"
#     destination_port_range     = "80"
#     source_address_prefix      = "*"
#     destination_address_prefix = "*"
#   }
# }

# resource "azurerm_subnet_network_security_group_association" "public1_nsg_association" {
#   subnet_id                 = azurerm_subnet.public1.id
#   network_security_group_id = azurerm_network_security_group.sg.id

# }
# resource "azurerm_subnet_network_security_group_association" "public2_nsg_association" {
#   subnet_id                 = azurerm_subnet.public2.id
#   network_security_group_id = azurerm_network_security_group.sg.id

# }

resource "azurerm_route_table" "Rota_AWS" {
  name                = "tabela_vpn"
  location            = azurerm_resource_group.grupo.location
  resource_group_name = azurerm_resource_group.grupo.name

  route {
    name           = "route1"
    address_prefix = "192.168.1.0/24"
    next_hop_type  = azurerm_virtual_network_gateway.vpn_gateway.id
  }
}

resource "azurerm_route_table_association" "Associacao_tabela" {
  subnet_id      = azurerm_subnet.public1.id
  route_table_id = azurerm_route_table.Rota_AWS.id
}