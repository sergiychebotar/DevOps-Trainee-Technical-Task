terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "2.99.0"
    }
  }
}

// ID's and secrets are not real!!!!!
provider "azurerm" {
  subscription_id = "f043df53-bac4-4fe2-9a14-fec4e51856b2"
  client_id       = "ddd42ddf-3443-4b52-9753-216c9942e9fb"
  client_secret   = "v7D8Q~sVZUL4ppCC.rb0NPHmMkpLAFsMEQtylbtK"
  tenant_id       = "9aa42d24-920c-44f7-8b74-165044d33d4c"
  features {}
}


locals {
  resource_group="app-grp"
  location="North Europe"  
}


resource "azurerm_resource_group" "app_grp"{
  name=local.resource_group
  location=local.location
}

resource "azurerm_virtual_network" "app_network" {
  name                = "app-network"
  location            = local.location
  resource_group_name = azurerm_resource_group.app_grp.name
  address_space       = ["10.0.0.0/16"]  
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_subnet" "SubnetA" {
  name                 = "SubnetA"
  resource_group_name  = azurerm_resource_group.app_grp.name
  virtual_network_name = azurerm_virtual_network.app_network.name
  address_prefixes     = ["10.0.0.0/24"]
  depends_on = [
    azurerm_virtual_network.app_network
  ]
}

resource "azurerm_public_ip" "PublicIPForVM1" {
  name                = "PublicIPForVM1"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_public_ip" "PublicIPForVM2" {
  name                = "PublicIPForVM2"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  allocation_method   = "Static"
  sku = "Standard"
}


// This interface is for appvm1
resource "azurerm_network_interface" "app_interface1" {
  name                = "app-interface1"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.PublicIPForVM1.id   
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_subnet.SubnetA
  ]
}

// This interface is for appvm2
resource "azurerm_network_interface" "app_interface2" {
  name                = "app-interface2"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.SubnetA.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.PublicIPForVM2.id
  }

  depends_on = [
    azurerm_virtual_network.app_network,
    azurerm_subnet.SubnetA
  ]
}

// This is the resource for appvm1
resource "azurerm_windows_virtual_machine" "app_vm1" {
  name                = "appvm1"
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  size                = "Standard_B1ms"
  zone                = 2
  admin_username      = "demousr"
  admin_password      = "SuperStrongPassword"
  #availability_set_id = azurerm_availability_set.app_set.id
  network_interface_ids = [
    azurerm_network_interface.app_interface1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface1,
    azurerm_availability_set.app_set
  ]
}

// This is the resource for appvm2
resource "azurerm_windows_virtual_machine" "app_vm2" {
  name                = "appvm2"
  resource_group_name = azurerm_resource_group.app_grp.name
  location            = azurerm_resource_group.app_grp.location
  size                = "Standard_B1ms"
  zone                = 1
  admin_username      = "demousr"
  admin_password      = "SuperStrongPassword"
  #availability_set_id = azurerm_availability_set.app_set.id
  network_interface_ids = [
    azurerm_network_interface.app_interface2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  depends_on = [
    azurerm_network_interface.app_interface2,
    azurerm_availability_set.app_set
  ]
}


resource "azurerm_availability_set" "app_set" {
  name                = "app-set"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  platform_fault_domain_count = 2
  platform_update_domain_count = 2  
  depends_on = [
    azurerm_resource_group.app_grp
  ]
}

resource "azurerm_storage_account" "appstore" {
  name                     = "mysimpleteststorageacc"
  resource_group_name      = azurerm_resource_group.app_grp.name
  location                 = azurerm_resource_group.app_grp.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  allow_blob_public_access = true
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = "mysimpleteststorageacc"
  container_access_type = "blob"
  depends_on=[
    azurerm_storage_account.appstore
    ]
}

# Here we are uploading our WinRM Configuration script as a blob
# to the Azure storage account

resource "azurerm_storage_blob" "winrm" {
  name                   = "sc.zip"
  storage_account_name   = "mysimpleteststorageacc"
  storage_container_name = "data"
  type                   = "Block"
  source                 = "sc.zip"
   depends_on=[azurerm_storage_container.data]
}

// This is the extension for appvm2
resource "azurerm_virtual_machine_extension" "vm_extension1" {
  name                 = "appvm-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.winrm
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.appstore.name}.blob.core.windows.net/data/sc.zip"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted Expand-Archive -Path sc.zip -DestinationPath C:\\ & powershell -ExecutionPolicy Unrestricted -file c:\\winrm.ps1"     
    }
SETTINGS
}


// This is the extension for appvm2
resource "azurerm_virtual_machine_extension" "vm_extension2" {
  name                 = "appvm-extension"
  virtual_machine_id   = azurerm_windows_virtual_machine.app_vm2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  depends_on = [
    azurerm_storage_blob.winrm
  ]
  settings = <<SETTINGS
    {
        "fileUris": ["https://${azurerm_storage_account.appstore.name}.blob.core.windows.net/data/sc.zip"],
          "commandToExecute": "powershell -ExecutionPolicy Unrestricted Expand-Archive -Path sc.zip -DestinationPath C:\\ & powershell -ExecutionPolicy Unrestricted -file c:\\winrm.ps1"     
    }
SETTINGS
}

resource "azurerm_network_security_group" "app_nsg" {
  name                = "app-nsg"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

# We are creating a rule to allow traffic on port 80
  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  /*   Optional RDP Access
  security_rule {
    name                       = "Allow_RDP"
    priority                   = 201
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3389"
    source_address_prefix      = "*"
    destination_address_prefix = "*" 
  } */
  security_rule {
    name                       = "Allow_WINRM"
    priority                   = 202
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "5985"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = azurerm_subnet.SubnetA.id
  network_security_group_id = azurerm_network_security_group.app_nsg.id
  depends_on = [
    azurerm_network_security_group.app_nsg
  ]
}

resource "azurerm_public_ip" "PublicIPForLB" {
  name                = "PublicIPForLB"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name
  allocation_method   = "Static"
  sku = "Standard"
}

resource "azurerm_lb" "TestLoadBalancer" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.app_grp.location
  resource_group_name = azurerm_resource_group.app_grp.name

  frontend_ip_configuration {
    name                 = "frontendIP"
    public_ip_address_id = azurerm_public_ip.PublicIPForLB.id
  }
  sku = "Standard"
  depends_on = [
    azurerm_public_ip.PublicIPForLB
  ]
}

resource "azurerm_lb_backend_address_pool" "PoolA" {
  loadbalancer_id = azurerm_lb.TestLoadBalancer.id
  name            = "PoolA"
  depends_on = [
    azurerm_lb.TestLoadBalancer
  ]
}

resource "azurerm_lb_backend_address_pool_address" "appvm1_address" {
  name                                = "appvm1"
  backend_address_pool_id             = azurerm_lb_backend_address_pool.PoolA.id
  virtual_network_id                  = azurerm_virtual_network.app_network.id
  ip_address                          = azurerm_network_interface.app_interface1.private_ip_address
  depends_on = [
    azurerm_lb_backend_address_pool.PoolA
  ]
}

resource "azurerm_lb_backend_address_pool_address" "appvm2_address" {
  name                                = "appvm2"
  backend_address_pool_id             = azurerm_lb_backend_address_pool.PoolA.id
  virtual_network_id                  = azurerm_virtual_network.app_network.id
  ip_address                          = azurerm_network_interface.app_interface2.private_ip_address
  depends_on = [
    azurerm_lb_backend_address_pool.PoolA
  ]
}

resource "azurerm_lb_probe" "ProbeA" {
  resource_group_name = azurerm_resource_group.app_grp.name
  loadbalancer_id     = azurerm_lb.TestLoadBalancer.id
  name                = "ProbeA"
  port                = 80
  depends_on = [
    azurerm_lb.TestLoadBalancer
  ]
}

resource "azurerm_lb_rule" "RuleA" {
  resource_group_name            = azurerm_resource_group.app_grp.name
  loadbalancer_id                = azurerm_lb.TestLoadBalancer.id
  name                           = "RuleA"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "frontendIP"
  backend_address_pool_ids = [ azurerm_lb_backend_address_pool.PoolA.id]
  probe_id = azurerm_lb_probe.ProbeA.id
  depends_on = [
    azurerm_lb.TestLoadBalancer,
    azurerm_lb_probe.ProbeA
  ]
}