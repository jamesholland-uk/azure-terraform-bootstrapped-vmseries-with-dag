variable "the_rama" { default = "" }
variable "the_vmauthkey" { default = "" }
variable "the_rama_apikey" { default = "" }
variable "the_ngfw_user" { default = "" }
variable "the_ngfw_password" { default = "" }
variable "the_csp_pinid" { default = "" }
variable "the_csp_pinvalue" { default = "" }

module "panos-hub" {
  source = "./tf-azure-common-firewall"

  // Azure Configuration
  resource_group_name = "test_res_group"
  resource_location   = "UK South"

  virtual_network_name = "vnet"
  virtual_network_cidr = "10.1.0.0/16"

  // Panorama Configuration
  
  panorama = {
    primary     = var.the_rama
    secondary   = ""
    vm_auth_key = var.the_vmauthkey
    apikey      = var.the_rama_apikey
  }

  // VM-Series
  vmseries = {
    no_of_instances = 2
    version         = "10.0.4"
    license         = "bundle2"
    offer           = "vmseries-flex"
    instance_size   = "Standard_DS3_v2"
    authcodes       = ""

    admin_username = var.the_ngfw_user
    admin_password = var.the_ngfw_password

    public_management = true
  }

  // CSP Self Registration
  csp_pin_id    = var.the_csp_pinid
  csp_pin_value = var.the_csp_pinvalue
}

output "trust-ips" {
  value = module.panos-hub.firewall-trust-ip
}