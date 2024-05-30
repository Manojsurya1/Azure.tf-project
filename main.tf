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

# Resource Group
resource "azurerm_resource_group" "azureproject" {
  name     = "azureproject-resources1"
  location = "West US"
}

# Virtual Network
resource "azurerm_virtual_network" "Manoj" {
  name                = "Manojworkspace-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.azureproject.location
  resource_group_name = azurerm_resource_group.azureproject.name
}

# Subnets
resource "azurerm_subnet" "subnet1" {
  name                 = "azsubnet1"
  resource_group_name  = azurerm_resource_group.azureproject.name
  virtual_network_name = azurerm_virtual_network.Manoj.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "apim-subnet" {
  name                 = "azsubnet2"
  resource_group_name  = azurerm_resource_group.azureproject.name
  virtual_network_name = azurerm_virtual_network.Manoj.name
  address_prefixes     = ["10.0.0.1/27"]
}

resource "azurerm_subnet" "db-subnet" {
  name                 = "azsubnet3"
  resource_group_name  = azurerm_resource_group.azureproject.name
  virtual_network_name = azurerm_virtual_network.Manoj.name
  address_prefixes     = ["10.8.0.16/28"]
}

# Public IP
resource "azurerm_public_ip" "az-pubip" {
  name                     = "pubip"
  resource_group_name      = azurerm_resource_group.azureproject.name
  location                 = azurerm_resource_group.azureproject.location
  allocation_method        = "Dynamic"
}

# Network Interface
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

# API Management
resource "azurerm_api_management" "Apim" {
  name                = "az-apim"
  location            = azurerm_resource_group.azureproject.location
  resource_group_name = azurerm_resource_group.azureproject.name
  publisher_name      = "My Brand"
  publisher_email     = "manojsurya@gmail.com"
  sku_name            = "Developer_1"
}

# App Service Plan
resource "azurerm_service_plan" "Limited" {
  name                = "test-app-service-plan"
  resource_group_name = azurerm_resource_group.azureproject.name
  location            = azurerm_resource_group.azureproject.location
  os_type             = "Windows"
  sku_name            = "Y1"
}
# Storage Account
resource "azurerm_storage_account" "c-db" {
  name                     = "test17storageacct"
  resource_group_name      = azurerm_resource_group.azureproject.name
  location                 = azurerm_resource_group.azureproject.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Function App
resource "azurerm_windows_function_app" "task" {
  name                = "task-windows-function-app"
  resource_group_name = azurerm_resource_group.azureproject.name
  location            = azurerm_resource_group.azureproject.location

  storage_account_name       = azurerm_storage_account.c-db.name
  storage_account_access_key = azurerm_storage_account.c-db.primary_access_key
  service_plan_id            = azurerm_service_plan.Limited.id

  site_config {}
}

# Cosmos DB Account
resource "azurerm_cosmosdb_account" "c-db" {
  name                = "db007"
  location            = azurerm_resource_group.azureproject.location
  resource_group_name = azurerm_resource_group.azureproject.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  consistency_policy {
      consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.azureproject.location
    failover_priority = 0
  }
}

# Cosmos DB SQL Database
resource "azurerm_cosmosdb_sql_database" "c-db" {
  name                = "sql-db"
  resource_group_name = azurerm_resource_group.azureproject.name
  account_name        = azurerm_cosmosdb_account.c-db.name
}

# Cosmos DB SQL Container
resource "azurerm_cosmosdb_sql_container" "container" {
  name                = "cosmosdbcontainer"
  resource_group_name = azurerm_resource_group.azureproject.name
  account_name        = azurerm_cosmosdb_account.c-db.name
  database_name       = azurerm_cosmosdb_sql_database.c-db.name
  partition_key_path  = "/id"
  throughput          = 400
}
