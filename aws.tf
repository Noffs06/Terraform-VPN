resource "aws_vpc" "vpn_vpc" {
  cidr_block = "192.168.0.0/16"
}

resource "aws_subnet" "vpn_subnet" {
  vpc_id            = aws_vpc.vpn_vpc.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_vpn_gateway" "vpn_gateway" {
  vpc_id = aws_vpc.vpn_vpc.id
}

resource "aws_customer_gateway" "cg" {
  bgp_asn    = 65000
  ip_address = azurerm_public_ip.vpn_gateway_ip.ip_address
  type       = "ipsec.1"
}

resource "aws_vpn_connection" "vpn_connection" {
  vpn_gateway_id      = aws_vpn_gateway.vpn_gateway.id
  customer_gateway_id = aws_customer_gateway.cg.id
  type                = "ipsec.1"

  static_routes_only = true


}

resource "aws_route_table" "vpn_route_table" {
  vpc_id = aws_vpc.vpn_vpc.id
  
  route {
    cidr_block = "172.16.1.0/24"
    gateway_id = aws_vpn_gateway.vpn_gateway.id
  }
}

resource "aws_route_table_association" "vpn_route_table_association" {
  subnet_id      = aws_subnet.vpn_subnet.id
  route_table_id = aws_route_table.vpn_route_table.id
}


resource "aws_security_group" "allow_icmp" {
  name        = "allow-icmp"
  description = "Allow ICMP traffic from Azure VPC"
  vpc_id      = aws_vpc.vpn_vpc.id

  ingress {
    from_port   = -1                       
    to_port     = -1                       
    protocol    = "icmp"
    cidr_blocks = ["172.16.1.0/24"]        
  }

  egress {
    from_port   = -1                       
    to_port     = -1                       
    protocol    = "icmp"
    cidr_blocks = ["172.16.1.0/24"]        
  }
}

#MAQUINA VIRTUAL UBUNTU COM BOTSTRAPPING COM SERVIDOR ZABIX

variable "azure_vm_private_ip" {
  description = "O IP privado da VM Azure"
  type        = string
}

resource "aws_instance" "zabbix_server" {
  ami           = "ami-0866a3c8686eaeeba" # Substitua por uma AMI compatível com Ubuntu ou outra de sua preferência
  instance_type = "t2.medium"
  subnet_id     = aws_subnet.vpn_subnet.id
  security_groups = [aws_security_group.allow_icmp.id] # Reutilizando o Security Group existente para permitir ICMP

  tags = {
    Name = "Zabbix-Server-AWS"
  }

  user_data = <<-EOF
  #!/bin/bash
  sudo su -

  # Instalar o Zabbix
  wget https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
  dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb

  # Atualizar o sources list e baixar as dependências necessárias
  apt update -y
  apt install zabbix-server-mysql zabbix-frontend-php zabbix-apache-conf zabbix-sql-scripts zabbix-agent mysql-server -y

  # Configuração do banco de dados
  mysql -u root --password="" -e "create database zabbix character set utf8mb4 collate utf8mb4_bin;"
  mysql -u root --password="" -e "create user zabbix@localhost identified by 'Senai@134';"
  mysql -u root --password="" -e "grant all privileges on zabbix.* to zabbix@localhost;"
  mysql -u root --password="" -e "set global log_bin_trust_function_creators = 1;"

  zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix --password="Senai@134" zabbix

  mysql -u root --password="" -e "set global log_bin_trust_function_creators = 0;"

  # Substituir a senha no arquivo de configuração
  sed -i '129s/# DBPassword=/DBPassword=Senai@134/' /etc/zabbix/zabbix_server.conf

  # Reiniciar os serviços
  systemctl restart zabbix-server.service zabbix-agent.service apache2.service
  systemctl enable zabbix-server.service zabbix-agent.service apache2.service

  # Instalar GlusterFS
  sudo apt-get update -y
  sudo apt-get install -y glusterfs-server

  # Iniciar o serviço GlusterFS
  sudo systemctl start glusterfs
  sudo systemctl enable glusterfs

  # Exibir status do serviço GlusterFS
  sudo systemctl status glusterfs

  # Adicionar o peer da instância da Azure
  sudo gluster peer probe ${aws_instance.zabbix_server.private_ip}

  # Criar o volume GlusterFS
  sudo gluster volume create gv0 replica 2 ${aws_instance.zabbix_server.network_interface[0].private_ip}:/data ${azurerm_network_interface.zabbix_server.private_ip}:/data

  # Iniciar o volume GlusterFS
  sudo gluster volume start gv0
  EOF
}
