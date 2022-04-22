resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-${terraform.workspace}-${var.rg_name}"
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-${terraform.workspace}-${var.vnet_name}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

}

resource "azurerm_subnet" "subnet" {
  name                 = "${var.prefix}-${terraform.workspace}-${var.subnet_name}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "publicip" {
  name                = "${var.prefix}-${terraform.workspace}-${var.public_ip}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Dynamic"
}

resource "azurerm_network_security_group" "nsg" {
  name                = "${var.prefix}-${terraform.workspace}-${var.ngs_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "ssh"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"

    }

}

resource "azurerm_network_interface" "nic" {
  name                       = "${var.prefix}-${terraform.workspace}-${var.nic_name}"
  resource_group_name = azurerm_resource_group.rg.name
  location = azurerm_resource_group.rg.location

  ip_configuration {
    name = "internal"
    subnet_id                  = azurerm_subnet.subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id       = azurerm_public_ip.publicip.id
  }
}

##### Connect SG to the network interface
resource "azurerm_network_interface_security_group_association" "nsg_association" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

##### Generate ramdom text for a unique storage account name
resource "random_id" "ramdomId" {
  keepers = {
    resource_group_name = "${azurerm_resource_group.rg.name}"
  }
  byte_length = 4
}

##### Create storage account for boot diagnostics
resource "azurerm_storage_account" "storage" {
  name                     = "${terraform.workspace}${random_id.ramdomId.dec}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier              = "Standard"
  account_replication_type = "LRS"
}


#### Create and display an SSH Key (PEM)
resource "tls_private_key" "rsa_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "app" {
  name                  = "${var.prefix}-${terraform.workspace}-${var.vm_app_name}"
  count = 2
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS1_v2"

  os_disk {
    name                 = "${var.prefix}-${terraform.workspace}-os-disk"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  computer_name                   = "Myvm"
  admin_username                  = "azureuser"
  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.rsa_ssh_key.public_key_openssh
  }


  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.storage.primary_blob_endpoint
  }
}

########### Export pem

variable path {
    default = "/Users/abrek/Documents/terraform/learnIAC_udemy/05_VM/keys"
}

locals {
  public_key_filename  = "${var.path}/key.pub"
  private_key_filename = "${var.path}/key.pem"
}

resource "local_file" "public_key_openssh" {
  count    = var.path != "" ? 1 : 0
  content  = tls_private_key.rsa_ssh_key.public_key_openssh
  filename = local.public_key_filename
}

resource "local_file" "private_key_pem" {
  count    = var.path != "" ? 1 : 0
  content  = tls_private_key.rsa_ssh_key.private_key_pem
  filename = local.private_key_filename
}

resource "null_resource" "chmod" {
  count      = var.path != "" ? 1 : 0
  depends_on = [local_file.private_key_pem]

  triggers = {
    key = tls_private_key.rsa_ssh_key.private_key_pem
  }

  provisioner "local-exec" {
    command = "chmod 600 ${local.private_key_filename}"
  }
}