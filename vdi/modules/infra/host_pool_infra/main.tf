# Create AVD host pool
resource "azurerm_virtual_desktop_host_pool" "hostpool" {
  resource_group_name              = data.azurerm_resource_group.main.name
  location                         = var.location
  name                             = var.hostpool_name
  friendly_name                    = var.hostpool_name
  validate_environment             = false
  personal_desktop_assignment_type = "Automatic"
  custom_rdp_properties            = "targetisaadjoined:i:1;drivestoredirect:s:*;audiomode:i:0;videoplaybackmode:i:1;redirectclipboard:i:1;redirectprinters:i:1;devicestoredirect:s:*;redirectcomports:i:1;redirectsmartcards:i:1;usbdevicestoredirect:s:*;enablecredsspsupport:i:1;redirectwebauthn:i:1;use multimon:i:1;"
  description                      = "${var.location} HostPool"
  type                             = "Personal"
  load_balancer_type               = "Persistent" #[BreadthFirst DepthFirst]
  start_vm_on_connect              = true
  #maximum_sessions_allowed         = 1
  scheduled_agent_updates {
    enabled = true
    schedule {
      day_of_week = "Saturday"
      hour_of_day = 2
    }
  }
}
resource "time_rotating" "main" {
  //rotation_hours = 2
  rotation_days = 10
}


resource "azurerm_virtual_desktop_host_pool_registration_info" "registrationinfo" {
  depends_on      = [time_rotating.main]
  hostpool_id     = azurerm_virtual_desktop_host_pool.hostpool.id
  expiration_date = time_rotating.main.rotation_rfc3339
}
