
provider "azurerm"{
    version = "~>1.31.0"
}
############################
#create a new resource group
############################
resource "azurerm_resource_group" "rg" {
    name = "TEL-TEST"
    location = "eastus"
    tags = {
        Environment = "Production"
        Team = "DevOps"
    }
}
#######################################################
#create a virtual network to live inside resource group
#######################################################
resource "azurerm_virtual_network" "vnet" {
    name = "terranet"
    address_space = list("10.0.0.0/16")
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
}

########################################
#create a subnet for the virtual network
########################################
resource "azurerm_subnet" "subnet" {
    name = "TELfrontendsub01"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix = "10.0.1.0/24"
}

#######################################################
#create a second subnet for sql server and sql database
#######################################################
resource "azurerm_subnet" "subnet02" {
    name = "TELbackendsub02"
    resource_group_name = azurerm_resource_group.rg.name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefix = "10.0.2.0/24"
}

###################
#create a public IP
###################
resource "azurerm_public_ip" "publicip" {
    name = "TELPubIp01"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
}

##########################
#create a second public IP
##########################
resource "azurerm_public_ip" "publicip2" {
    name = "TELPubIp02"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    allocation_method = "Static"
}



###################################################
#create a network security group and add some rules
###################################################
resource "azurerm_network_security_group" "nsg" {
    name = "johnsNSG"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name = "AllowHTTP"
        priority = 310
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "80"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
    security_rule {
                name = "AllowSSH"
        priority = 300
        direction = "Inbound"
        access = "Allow"
        protocol = "Tcp"
        source_port_range = "*"
        destination_port_range = "22"
        source_address_prefix = "*"
        destination_address_prefix = "*"
    }
}

#############
#create a NIC
#############
resource "azurerm_network_interface" "nic" {
    name = "myNIC"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
        name = "myNICCONFIG"
        subnet_id = azurerm_subnet.subnet.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = azurerm_public_ip.publicip.id 
    }
}

####################
#create a second NIC
####################
resource "azurerm_network_interface" "nic02" {
    name = "myNIC02"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    network_security_group_id = azurerm_network_security_group.nsg.id

    ip_configuration {
        name = "myNICCONFIG"
        subnet_id = azurerm_subnet.subnet02.id
        private_ip_address_allocation = "dynamic"
        public_ip_address_id = azurerm_public_ip.publicip2.id 
    }
}

#########################
#create a storage account
#########################
resource "azurerm_storage_account" "stor" {
    name = "johnterrastore"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    account_tier = "Standard"
    account_replication_type = "LRS"
}

###############################
#create a linux virtual machine
###############################
resource "azurerm_virtual_machine" "vm" {
    name = "telwebserv01"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic.id]
    vm_size = "Standard_DS1_v2"

    storage_os_disk {
        name = "firstVMos"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }

    os_profile {
        computer_name = "myUbuntu"
        admin_username = "AzureAdmin"
        admin_password = "Password123!@"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    provisioner "remote-exec" {
        connection {
            type = "ssh"
            host = azurerm_public_ip.publicip.ip_address
            user = "AzureAdmin"
            password = "Password123!@"
        }

        inline = [
            "sudo apt install apache2 -y",
            "sudo chmod -R 0755 /var/www/html/",
            "sudo systemctl enable apache2",
            "sudo systemctl start apache2",
            "sudo ufw allow in 'Apache Full'"
        ]
    }
}

######################################
#create a second linux virtual machine
######################################
resource "azurerm_virtual_machine" "vm02" {
    name = "telwebserv002"
    location = "eastus"
    resource_group_name = azurerm_resource_group.rg.name
    network_interface_ids = [azurerm_network_interface.nic02.id]
    vm_size = "Standard_DS1_v2"

    storage_os_disk {
        name = "firstVMos"
        caching = "ReadWrite"
        create_option = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer = "UbuntuServer"
        sku = "16.04-LTS"
        version = "latest"
    }

    os_profile {
        computer_name = "myUbuntu"
        admin_username = "AzureAdmin"
        admin_password = "Password123!@"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    provisioner "remote-exec" {
        connection {
            type = "ssh"
            host = azurerm_public_ip.publicip2.ip_address
            user = "AzureAdmin"
            password = "Password123!@"
        }

        inline = [
            "sudo apt install apache2 -y",
            "sudo chmod -R 0755 /var/www/html/",
            "sudo systemctl enable apache2",
            "sudo systemctl start apache2",
            "sudo ufw allow in 'Apache Full'"
        ]
    }
}
