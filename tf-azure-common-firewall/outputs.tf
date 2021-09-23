output "ingress-pip" {
  value = azurerm_public_ip.ingress.ip_address
}

output "firewall-management-pip" {
  value = azurerm_public_ip.management.*.ip_address
}

output "firewall-untrust-pip" {
  value = azurerm_public_ip.ethernet_0_1.*.ip_address
}

output "instrumentation_key" {
  value = azurerm_application_insights.main[0].instrumentation_key
}

output "firewall-trust-ip" {
  value = azurerm_network_interface.ethernet0_2.*.private_ip_address
}