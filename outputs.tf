output "resource_group_name" {
  value = azurerm_resource_group.student-rg.name
}

output "vm_private_ip_address" {
  value = formatlist("%s: %s", azurerm_linux_virtual_machine.student-vm.*.name, azurerm_network_interface.student-nic.*.private_ip_address)
}

output "public_ip_address" {
  value = formatlist("%s: %s", azurerm_linux_virtual_machine.student-vm.*.name, azurerm_linux_virtual_machine.student-vm.*.public_ip_address)
}