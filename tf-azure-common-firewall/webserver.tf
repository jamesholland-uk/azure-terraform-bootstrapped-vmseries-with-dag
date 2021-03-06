#----------------------------------------------------------------------------------------------------------------------
# Web Server
#----------------------------------------------------------------------------------------------------------------------



# Public IP Address:
/*resource "azurerm_public_ip" "management" {
  count               = var.vmseries.no_of_instances
  name                = "ngfw${count.index + 1}-nic-management-pip-${random_string.name.result}"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.main]
  sku                 = "Standard"
}*/

# Network Interface:
resource "azurerm_network_interface" "nic" {
  //count                = var.vmseries.no_of_instances
  name                 = "webserver-nic-${random_string.name.result}"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = false

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.trust.id
    private_ip_address_allocation = "Dynamic"
    //public_ip_address_id          = var.vmseries.public_management ? element(concat(azurerm_public_ip.management.*.id, tolist([""])), count.index) : ""
  }
  depends_on = [azurerm_resource_group.main]
}

# Network Security Group (Management)
resource "azurerm_network_interface_security_group_association" "nic" {
  //count                     = var.vmseries.no_of_instances
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.management.id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Ethernet0/1 Interface (Untrust)
#----------------------------------------------------------------------------------------------------------------------
/*
# Public IP Address
resource "azurerm_public_ip" "ethernet_0_1" {
  count               = var.vmseries.no_of_instances
  name                = "ngfw${count.index + 1}-nic-ethernet01-pip-${random_string.name.result}"
  location            = var.resource_location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  depends_on          = [azurerm_resource_group.main]
  sku                 = "Standard"
}

# Network Interface
resource "azurerm_network_interface" "ethernet0_1" {
  count                = var.vmseries.no_of_instances
  name                 = "ngfw${count.index + 1}-nic-ethernet01-${random_string.name.result}"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.untrust.id
    private_ip_address_allocation = "Dynamic"
    # public_ip_address_prefix_id = azurerm_public_ip_prefix.ethernet_0_1.id
    public_ip_address_id = length(azurerm_public_ip.ethernet_0_1) > 0 ? element(concat(azurerm_public_ip.ethernet_0_1.*.id, tolist([""])), count.index) : ""
  }
  depends_on = [azurerm_resource_group.main]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "ethernet0_1" {
  count                     = var.vmseries.no_of_instances
  network_interface_id      = azurerm_network_interface.ethernet0_1[count.index].id
  network_security_group_id = azurerm_network_security_group.data.id
}

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Ethernet0/2 Interface (Trust)
#----------------------------------------------------------------------------------------------------------------------

# Network Interface
resource "azurerm_network_interface" "ethernet0_2" {
  count                = var.vmseries.no_of_instances
  name                 = "ngfw${count.index + 1}-nic-ethernet02-${random_string.name.result}"
  location             = var.resource_location
  resource_group_name  = var.resource_group_name
  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.trust.id
    private_ip_address_allocation = "Dynamic"
  }
  depends_on = [azurerm_resource_group.main]
}

# Network Security Group (Data)
resource "azurerm_network_interface_security_group_association" "ethernet0_2" {
  count                     = var.vmseries.no_of_instances
  network_interface_id      = azurerm_network_interface.ethernet0_2[count.index].id
  network_security_group_id = azurerm_network_security_group.data.id
}
*/

#----------------------------------------------------------------------------------------------------------------------
# VM-Series - Virtual Machine
#----------------------------------------------------------------------------------------------------------------------

resource "azurerm_linux_virtual_machine" "webserver" {
  //count = var.vmseries.no_of_instances

  # Resource Group & Location:
  resource_group_name = var.resource_group_name
  location            = var.resource_location

  name = "webserver-vm-${random_string.name.result}"

  # Availabilty Zone:
  //zone = (count.index % 3) + 1

  # Instance
  size = var.vmseries.instance_size

  # Username and Password Authentication:
  disable_password_authentication = false
  admin_username                  = var.vmseries.admin_username
  admin_password                  = var.vmseries.admin_password

  # Network Interfaces:
  network_interface_ids = [
    azurerm_network_interface.nic.id
    //element(azurerm_network_interface.management.*.id, count.index),
    //element(azurerm_network_interface.ethernet0_1.*.id, count.index),
    //element(azurerm_network_interface.ethernet0_2.*.id, count.index),
  ]

  # Tags
  //tags = { type = "webserver" }

  /*plan {
    name      = var.vmseries.license
    publisher = "paloaltonetworks"
    product   = var.vmseries.offer
  }*/

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  os_disk {
    name                 = "webserver-osdisk-${random_string.name.result}"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.diagstorageaccount.primary_blob_endpoint
  }

  # Bootstrap Information for Azure:
  /*
  custom_data = base64encode(join(
    ",",
    [
      "storage-account=${azurerm_storage_account.bootstrap.name}",
      "access-key=${azurerm_storage_account.bootstrap.primary_access_key}",
      "file-share=${azurerm_storage_share.bootstrap.name}",
      "share-directory=",
    ],
  ))*/

  # Dependencies:
  depends_on = [azurerm_network_interface.nic, azurerm_storage_account.diagstorageaccount]

}

resource "azurerm_storage_account" "diagstorageaccount" {
    name                        = "diagforjamestest"
    resource_group_name         = var.resource_group_name
    location                    = var.resource_location
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    depends_on = [
    azurerm_resource_group.main
  ]
}