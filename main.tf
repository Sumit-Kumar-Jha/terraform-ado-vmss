locals {
  # All variables used in this file should be 
  # added as locals here 
  location              = var.location
  vmsize                = var.vmsize
  
  # Common tags should go here
  tags           = {
    created_by = "Terraform"
  }
}

# Create a Virtual Network within the Resource Group
resource "azurerm_virtual_network" "ado-vnet" {
  name                = "ado-vnet"
  address_space       = ["10.100.0.0/16"]
  resource_group_name = data.azurerm_resource_group.project-rg.name
  location            = local.location 
}

# Create a Subnet within the Virtual Network
resource "azurerm_subnet" "internal" {
  name                 = "subnet-ado"
  virtual_network_name = azurerm_virtual_network.ado-vnet.name
  resource_group_name  = data.azurerm_resource_group.project-rg.name
  address_prefix       = "10.100.1.0/24"
}


resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_!-:=+*#"
  upper            = true
  number           = true
  lower            = true
}
    
resource "azurerm_linux_virtual_machine_scale_set" "ado-vmss" {
  name                            = "ado-vmss"
  resource_group_name             = data.azurerm_resource_group.project-rg.name
  location                        = local.location
  sku                             = local.vmsize 
  instances                       = 2
  admin_username                  = "adminuser"
  admin_password                  = random_password.password.result
  disable_password_authentication = false
  single_placement_group          = false
  overprovision                   = false
  platform_fault_domain_count     = 1
  source_image_id                 = data.azurerm_image.agent-image.id 
  upgrade_mode                    = "Manual"

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
}

# Create a Subnet within the Virtual Network
resource "azurerm_subnet" "AzureBastionSubnet" {
  name                 = "subnet-ado"
  virtual_network_name = azurerm_virtual_network.ado-vnet.name
  resource_group_name  = data.azurerm_resource_group.project-rg.name
  address_prefix       = "10.100.2.0/24"
}

resource "azurerm_public_ip" "bastion-pip" {
  name                = "bastionpip"
  location            = local.location
  resource_group_name = azurerm_resource_group.project-rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bastion-host" {
  name                = "bastion"
  location            = local.location
  resource_group_name = azurerm_resource_group.project-rg.name

  ip_configuration {
    name                 = "ip-config"
    subnet_id            = azurerm_subnet.AzureBastionSubnet.id 
    public_ip_address_id = azurerm_public_ip.bastion-pip.id
  }
}
