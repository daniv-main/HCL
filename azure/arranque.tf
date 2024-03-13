terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.94.0"
    }
  }
}
provider "azurerm" {
  subscription_id = "token"
  features {
   resource_group {
     prevent_deletion_if_contains_resources = false
     }
   }
}

resource "azurerm_resource_group" "RG_AzureTerraform" {
  name     = "RG_AzTerraform1"
  location = "uksouth"
}
resource "azurerm_public_ip" "IP_AzureTerraform" {
  name                = "IP_AzureTerraform"
  location            = azurerm_resource_group.RG_AzureTerraform.location
  resource_group_name = azurerm_resource_group.RG_AzureTerraform.name
  allocation_method   = "Dynamic"
}

resource "azurerm_virtual_network" "VN_AzureTerraform" {
  name                = "Red-AzureTerraform"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.RG_AzureTerraform.location
  resource_group_name = azurerm_resource_group.RG_AzureTerraform.name
}
resource "azurerm_subnet" "SN_AzureTerraform" {
  name                 = "SubNet-AzureTerraform"
  resource_group_name  = azurerm_resource_group.RG_AzureTerraform.name
  virtual_network_name = azurerm_virtual_network.VN_AzureTerraform.name
  address_prefixes     = ["10.0.1.0/24"]
}
resource "azurerm_network_interface" "NIC_AzureTerraform" {
  name                = "Nic-AzureTerraform"
  location            = azurerm_resource_group.RG_AzureTerraform.location
  resource_group_name = azurerm_resource_group.RG_AzureTerraform.name

  ip_configuration {
    name                          = "myNicConfiguration"
    subnet_id                     = azurerm_subnet.SN_AzureTerraform.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.IP_AzureTerraform.id
  }
}
resource "azurerm_subnet_network_security_group_association" "example" {
  subnet_id                 = azurerm_subnet.SN_AzureTerraform.id
  network_security_group_id = azurerm_network_security_group.NSG_AzureTerraform.id
}
resource "azurerm_network_security_group" "NSG_AzureTerraform" {
  name                = "NSG_AzureTerraform"
  location            = azurerm_resource_group.RG_AzureTerraform.location
  resource_group_name = azurerm_resource_group.RG_AzureTerraform.name

  security_rule {
    name                       = "ssh"
    priority                   = 101
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "cassandra"
    priority                   = 102
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9042"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "mongoDB"
    priority                   = 103
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "27017"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "mySQL"
    priority                   = 104
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "redis"
    priority                   = 105
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "6379"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  
}
resource "azurerm_virtual_machine" "VM-LinuxAzureTerraform" {
  name                  = "LinuxAzureTerraform"
  location              = azurerm_resource_group.RG_AzureTerraform.location
  resource_group_name   = azurerm_resource_group.RG_AzureTerraform.name
  network_interface_ids = [azurerm_network_interface.NIC_AzureTerraform.id]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "DiscoSistemaOperativo-Linux"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  os_profile {
    computer_name  = "LinuxAzureTerraform"
    admin_username = "azureuser"
  }


  os_profile_linux_config {
      disable_password_authentication = true
      ssh_keys {
        path     = "/home/azureuser/.ssh/authorized_keys"
        key_data = file("~/.ssh/id_rsa.pub")
      }
  }
}

output "ConexionWeb" {
  value = "http://${azurerm_public_ip.IP_AzureTerraform.ip_address}"
 }

