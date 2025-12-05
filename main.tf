terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "****************************"
}

#---------------------------------------------------------RESOURCE-GROUP - rg "project"

resource "azurerm_resource_group" "rg" {
  name     = "project"
  location = "Central India"
}

#---------------------------------------------------------VIRTUAL-NETWORKS -central_india_vnet -korea_central_vnet  "central-india-vnet" "korea-central-vnet"

resource "azurerm_virtual_network" "central_india_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "central-india-vnet"
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_virtual_network" "korea_central_vnet" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Korea Central"
  name                = "korea-central-vnet"
  address_space       = ["10.1.0.0/16"]
}

#--------------------------------------------------------SUBNETS -vmsubnet1 -vmsubnet2 -agsubnet1 -agsubnet2

resource "azurerm_subnet" "vmsubnet1" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.central_india_vnet.name
  name                 = "india-vm-subnet"
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "agsubnet1" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.central_india_vnet.name
  name                 = "india-ag-subnet"
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "vmsubnet2" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.korea_central_vnet.name
  name                 = "korea-vm-subnet"
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_subnet" "agsubnet2" {
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.korea_central_vnet.name
  name                 = "korea-ag-subnet"
  address_prefixes     = ["10.1.2.0/24"]
}

#-----------------------------------------------------------PUBLIC-IPs  -ag1ip -ag2ip

resource "azurerm_public_ip" "ag1ip" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  name                = "AG1-PUBLICIP"
  allocation_method   = "Static"
  domain_name_label   = "ag1-dns-${random_string.suffix.result}"
  sku                 = "Standard"
}

resource "azurerm_public_ip" "ag2ip" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Korea Central"
  name                = "AG2-PUBLICIP"
  allocation_method   = "Static"
  domain_name_label   = "ag2-dns-${random_string.suffix.result}"
  sku                 = "Standard"
}

#-------------------------------------------------------------LOCAL VARIABLES

locals {
  username = "appu"
  password = "APPUgowda#01"
}

#------------------------------------------------------------NICs  -india_vm1_nic -india_vm2_nic -korea_vm1_nic -korea_vm2_nic

resource "azurerm_network_interface" "india_vm1_nic" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Central India"
  name                = "india-vm1-nic"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vmsubnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.4"
  }
}

resource "azurerm_network_interface" "india_vm2_nic" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Central India"
  name                = "india-vm2-nic"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vmsubnet1.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.1.5"
  }
}

resource "azurerm_network_interface" "korea_vm1_nic" {
  depends_on          = [azurerm_subnet.vmsubnet2]
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Korea Central"
  name                = "korea-vm1-nic"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vmsubnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.4"
  }
}

resource "azurerm_network_interface" "korea_vm2_nic" {
  depends_on          = [azurerm_subnet.vmsubnet2]
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Korea Central"
  name                = "korea-vm2-nic"
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vmsubnet2.id
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.1.1.5"
  }
}

#-------------------------------------------------VIRTUAL-MACHINES -india_vm1 -india_vm2 -korea_vm1 -korea_vm2

resource "azurerm_linux_virtual_machine" "india_vm1" {
  name                            = "india-vm1"
  location                        = "Central India"
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B2s"
  admin_username                  = local.username
  admin_password                  = local.password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.india_vm1_nic.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "india-vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(file("${path.module}/indiavm1.sh"))
}

resource "azurerm_linux_virtual_machine" "india_vm2" {
  name                            = "india-vm2"
  location                        = "Central India"
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B2s"
  admin_username                  = local.username
  admin_password                  = local.password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.india_vm2_nic.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "india-vm2-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(templatefile("${path.module}/indiavm2.tftpl", {
    storage_account_name = azurerm_storage_account.sa.name
  }))

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_linux_virtual_machine" "korea_vm1" {
  name                            = "korea-vm1"
  location                        = "Korea Central"
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B2s"
  admin_username                  = local.username
  admin_password                  = local.password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.korea_vm1_nic.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "korea-vm1-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(file("${path.module}/koreavm1.sh"))
}

resource "azurerm_linux_virtual_machine" "korea_vm2" {
  name                            = "korea-vm2"
  location                        = "Korea Central"
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B2s"
  admin_username                  = local.username
  admin_password                  = local.password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.korea_vm2_nic.id]

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  os_disk {
    name                 = "korea-vm2-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  custom_data = base64encode(templatefile("${path.module}/koreavm2.tftpl", {
    storage_account_name = azurerm_storage_account.sa.name
  }))

  identity {
    type = "SystemAssigned"
  }
}

#-----------------------------------------------------APPLICATION-GATEWAYS  -ag1 -ag2
resource "azurerm_application_gateway" "ag1" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Central India"
  name                = "ag1"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "ag1ipcnfig"
    subnet_id = azurerm_subnet.agsubnet1.id
  }

  frontend_port {
    name = "port80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendConfig"
    public_ip_address_id = azurerm_public_ip.ag1ip.id
  }

  backend_address_pool {
    name         = "pool-vm1"
    ip_addresses = [azurerm_network_interface.india_vm1_nic.private_ip_address]
  }

  backend_address_pool {
    name         = "pool-vm2"
    ip_addresses = [azurerm_network_interface.india_vm2_nic.private_ip_address]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontendConfig"
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  url_path_map {
    name                               = "routing-map"
    default_backend_address_pool_name  = "pool-vm1"
    default_backend_http_settings_name = "http-settings"
    path_rule {
      name                       = "upload-path"
      paths                      = ["/upload", "/upload/*"]
      backend_address_pool_name  = "pool-vm2"
      backend_http_settings_name = "http-settings"
    }
  }

  request_routing_rule {
    name               = "rule1"
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener"
    url_path_map_name  = "routing-map"
    priority           = 100
  }
}

resource "azurerm_application_gateway" "ag2" {
  depends_on          = [azurerm_public_ip.ag2ip]
  resource_group_name = azurerm_resource_group.rg.name
  location            = "Korea Central"
  name                = "ag2"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "ag2ipcnfig"
    subnet_id = azurerm_subnet.agsubnet2.id
  }

  frontend_port {
    name = "port80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "frontendConfig"
    public_ip_address_id = azurerm_public_ip.ag2ip.id
  }

  backend_address_pool {
    name         = "pool-vm1"
    ip_addresses = [azurerm_network_interface.korea_vm1_nic.private_ip_address]
  }

  backend_address_pool {
    name         = "pool-vm2"
    ip_addresses = [azurerm_network_interface.korea_vm2_nic.private_ip_address]
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
  }

  http_listener {
    name                           = "listener"
    frontend_ip_configuration_name = "frontendConfig"
    frontend_port_name             = "port80"
    protocol                       = "Http"
  }

  url_path_map {
    name                               = "routing-map"
    default_backend_address_pool_name  = "pool-vm1"
    default_backend_http_settings_name = "http-settings"
    path_rule {
      name                       = "upload-path"
      paths                      = ["/upload", "/upload/*"]
      backend_address_pool_name  = "pool-vm2"
      backend_http_settings_name = "http-settings"
    }
  }

  request_routing_rule {
    name               = "rule1"
    rule_type          = "PathBasedRouting"
    http_listener_name = "listener"
    url_path_map_name  = "routing-map"
    priority           = 100
  }
}

#-----------------------------------------------------------TRAFFIC-MANAGER -traffic

resource "azurerm_traffic_manager_profile" "traffic" {
  resource_group_name    = azurerm_resource_group.rg.name
  name                   = "traffic-manager"
  profile_status         = "Enabled"
  traffic_routing_method = "Performance"

  dns_config {
    relative_name = "project-tm-appu-unique"
    ttl           = 60
  }

  monitor_config {
    protocol = "HTTP"
    port     = 80
    path     = "/"
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "india" {
  name                 = "india-endpoint"
  profile_id           = azurerm_traffic_manager_profile.traffic.id
  target_resource_id   = azurerm_public_ip.ag1ip.id
  always_serve_enabled = true
}

resource "azurerm_traffic_manager_azure_endpoint" "korea" {
  name                 = "korea-endpoint"
  profile_id           = azurerm_traffic_manager_profile.traffic.id
  target_resource_id   = azurerm_public_ip.ag2ip.id
  always_serve_enabled = true
}

output "traffic_manager_fqdn" {
  value = azurerm_traffic_manager_profile.traffic.fqdn
}

#-----------------------------------------------------------STORAGE-ACCOUNT
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "projectsa${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

resource "azurerm_role_assignment" "india_vm2_role" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.india_vm2.identity[0].principal_id
}

resource "azurerm_role_assignment" "korea_vm2_role" {
  scope                = azurerm_storage_account.sa.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_virtual_machine.korea_vm2.identity[0].principal_id
}
