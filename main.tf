resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

# Gerar grupo de recursos
resource "azurerm_resource_group" "student-rg" {
  location = var.resource_group_location
  name     = random_pet.rg_name.id
}

# Criar Rede Virtual
resource "azurerm_virtual_network" "student-vnet" {
  name                = "student-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.student-rg.location
  resource_group_name = azurerm_resource_group.student-rg.name
}

# Criar Subnet
resource "azurerm_subnet" "student-subnet" {
  name                 = "student-subnet"
  resource_group_name  = azurerm_resource_group.student-rg.name
  virtual_network_name = azurerm_virtual_network.student-vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "student-nsg" {
  name                = "student-nsg"
  resource_group_name = azurerm_resource_group.student-rg.name
  location            = azurerm_resource_group.student-rg.location

  security_rule {
    name                       = "student-nsg"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "HTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create Public IP
resource "azurerm_public_ip" "student-pip" {
  name                = "student-pip"
  location            = azurerm_resource_group.student-rg.location
  resource_group_name = azurerm_resource_group.student-rg.name
  allocation_method   = "Dynamic"
}

# Create network interface
resource "azurerm_network_interface" "student-nic" {
  name                = "student-nic"
  location            = azurerm_resource_group.student-rg.location
  resource_group_name = azurerm_resource_group.student-rg.name

  ip_configuration {
    name                          = "student-nic"
    subnet_id                     = azurerm_subnet.student-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.student-pip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "student-nsg-nic" {
  network_interface_id      = azurerm_network_interface.student-nic.id
  network_security_group_id = azurerm_network_security_group.student-nsg.id
}

resource "random_pet" "ssh_key_name" {
  prefix    = "ssh"
  separator = ""
}

resource "azapi_resource_action" "ssh_public_key_gen" {
  type                   = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  resource_id            = azapi_resource.ssh_public_key.id
  action                 = "generateKeyPair"
  method                 = "POST"
  response_export_values = ["publicKey", "privateKey"]
}

resource "azapi_resource" "ssh_public_key" {
  type      = "Microsoft.Compute/sshPublicKeys@2022-11-01"
  name      = random_pet.ssh_key_name.id
  location  = azurerm_resource_group.student-rg.location
  parent_id = azurerm_resource_group.student-rg.id
}

resource "local_file" "private_key" {
  content         = azapi_resource_action.ssh_public_key_gen.output.privateKey
  file_permission = 0600
  filename        = "private_key.pem"
}

# Cria VM
resource "azurerm_linux_virtual_machine" "student-vm" {
  name                            = "student-vm"
  location                        = azurerm_resource_group.student-rg.location
  resource_group_name             = azurerm_resource_group.student-rg.name
  network_interface_ids           = [azurerm_network_interface.student-nic]
  disable_password_authentication = false
  size                            = "Standard_B1s"
  computer_name                   = "student-vm"
  admin_username                  = var.username
  admin_password                  = var.admin_passwd
  os_disk {
    name                 = "student-vm-OsDisk"
    caching              = "ReadWrite"
    storage_account_type = "StandardSSD_LRS"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Gerar arquivo de inventário do Ansible
resource "local_file" "hosts_cfg" {
  content = templatefile("ansible-hosts.tpl",
    {
      web      = azurerm_linux_virtual_machine.student-vm.public_ip_address
      username = var.username
    }
  )
  filename = "./ansible/inventory.ini"
}
