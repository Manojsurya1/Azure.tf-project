terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "azureproject" {
  name     = "azureproject-resources1"
  location = "WEST US"
}

resource "azurerm_virtual_network" "Manoj" {
  name                = "Manojworkspace-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azureproject.location
  resource_group_name = azurerm_resource_group.azureproject.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "azsubnet1"
  resource_group_name  = azurerm_resource_group.azureproject.name
  virtual_network_name = azurerm_virtual_network.Manoj.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "az-pubip" {
  name                     = "pubip"
  resource_group_name = azurerm_resource_group.azureproject.name
  location                 = azurerm_resource_group.azureproject.location
  allocation_method        = "Dynamic"
}

resource "azurerm_network_interface" "aznetwork" {
  name                = "aznetwork"
  location            = azurerm_resource_group.azureproject.location
  resource_group_name = azurerm_resource_group.azureproject.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.az-pubip.id
  }
}

resource "azurerm_linux_virtual_machine" "VM" {
  name                = "example-machine"
  resource_group_name = azurerm_resource_group.azureproject.name
  location            = azurerm_resource_group.azureproject.location
  size                = "Standard_F2"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.aznetwork.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}