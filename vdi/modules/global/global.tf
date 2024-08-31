resource "azurerm_role_assignment" "avd_role_assignment" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = data.azuread_service_principal.avd_spn.object_id
}
data "azurerm_subscription" "primary" {

}

data "azuread_service_principal" "avd_spn" {
  client_id = "9cdead84-a844-4324-93f2-b2e6bb768d07"
}
