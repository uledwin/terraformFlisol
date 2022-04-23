output "tls_private_key" {
  value     = tls_private_key.rsa_ssh_key.private_key_pem
  sensitive = true
}

output "public_ip" {
  value = azurerm_linux_virtual_machine.app.*.public_ip_address
}

