terraform {
  required_version = ">= 1.6.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  resource_provider_registrations = "none"
  subscription_id                 = var.subscription_id
}

provider "azapi" {
  subscription_id = var.subscription_id
}

locals {
  virtual_network_name        = "${var.vm_name}-vnet"
  subnet_name                 = "default"
  public_ip_name              = "${var.vm_name}-ip"
  network_security_group_name = "${var.vm_name}-nsg"
}

resource "azurerm_public_ip" "vm" {
  name                = local.public_ip_name
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_security_group" "vm" {
  name                = local.network_security_group_name
  location            = var.location
  resource_group_name = var.resource_group_name

  security_rule {
    name                       = "AllowSSH"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_virtual_network" "vm" {
  name                = local.virtual_network_name
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "vm" {
  name                 = local.subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.vm.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_network_interface" "vm" {
  name                = var.network_interface_name
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_network_interface_security_group_association" "vm" {
  network_interface_id      = azurerm_network_interface.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_storage_account" "vmstorage" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location

  account_tier             = "Standard"
  account_replication_type = "LRS"

  account_kind = "StorageV2"

  min_tls_version          = "TLS1_2"
  https_traffic_only_enabled = true

  allow_nested_items_to_be_public = false

  tags = {
    Environment = "Dev"
    CreatedBy   = "Terraform"
  }
}

resource "azapi_resource" "virtual_machine" {
  type      = "Microsoft.Compute/virtualMachines@2024-11-01"
  name      = var.vm_name
  location  = var.location
  parent_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}"

  schema_validation_enabled = false

  body = {
    properties = {
      hardwareProfile = {
        vmSize = var.vm_size
      }
      additionalCapabilities = {
        hibernationEnabled = false
      }
      storageProfile = {
        imageReference = {
          publisher = "canonical"
          offer     = "ubuntu-24_04-lts"
          sku       = "ubuntu-pro"
          version   = "latest"
        }
        osDisk = {
          osType       = "Linux"
          name         = var.os_disk_name
          createOption = "FromImage"
          caching      = "ReadWrite"
          deleteOption = "Delete"
        }
        dataDisks          = []
        diskControllerType = "SCSI"
      }
      osProfile = {
        computerName  = var.vm_name
        adminUsername = var.admin_username
        adminPassword = var.admin_password
        linuxConfiguration = {
          disablePasswordAuthentication = false
          provisionVMAgent              = true
          patchSettings = {
            patchMode      = "ImageDefault"
            assessmentMode = "ImageDefault"
          }
        }
        secrets                  = []
        allowExtensionOperations = true
      }
      securityProfile = {
        uefiSettings = {
          secureBootEnabled = true
          vTpmEnabled       = true
        }
        securityType = "TrustedLaunch"
      }
      networkProfile = {
        networkInterfaces = [
          {
            id = azurerm_network_interface.vm.id
            properties = {
              deleteOption = "Delete"
            }
          }
        ]
      }
      diagnosticsProfile = {
        bootDiagnostics = {
          enabled = true
        }
      }
    }
  }
}
