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
  address_prefix       = "10.100.1.0/26"
}


resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "_!-:=+*#"
  upper            = true
  number           = true
  lower            = true
}
    
# Create virtual machine
resource "azurerm_virtual_machine" "vm" {
  name                  = "vmterraform"
  location              = local.location
  resource_group_name   = data.azurerm_resource_group.project-rg.name
  vm_size               = local.vmsize

  storage_os_disk {
    name              = "stvmpmvmterraformos"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
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

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_profile {
    computer_name  = "vmterraform"
    admin_username = "adminuser"
    admin_password = random_password.password.result
  }