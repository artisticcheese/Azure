
resource "azurerm_role_assignment" "scalingplan-rbac" {
  scope                = data.azurerm_resource_group.main.id
  role_definition_name = "Desktop Virtualization Power On Off Contributor"
  principal_id         = data.azuread_service_principal.avd-sp.object_id
}
resource "azapi_resource" "weekdays_personal_schedule_root" {
  type      = "Microsoft.DesktopVirtualization/scalingPlans@2023-11-01-preview"
  name      = "${var.hostpool_name}-scaling-plan"
  location  = azurerm_virtual_desktop_host_pool.hostpool.location
  parent_id = data.azurerm_resource_group.main.id
  body = jsonencode({
    properties = {
      timeZone     = var.time_zone_for_scaling,
      hostPoolType = "Personal",
      exclusionTag = "no-schedule",
      schedules    = [],
      hostPoolReferences = [
        {
          hostPoolArmPath    = azurerm_virtual_desktop_host_pool.hostpool.id,
          scalingPlanEnabled = true
        }
      ],
  } })
  depends_on = [azurerm_role_assignment.scalingplan-rbac]
}


resource "azapi_resource" "weekdays_personal_schedule" {
  type      = "Microsoft.DesktopVirtualization/scalingPlans/personalSchedules@2023-11-01-preview"
  name      = "Weekdays"
  parent_id = azapi_resource.weekdays_personal_schedule_root.id
  body = jsonencode({
    properties = {
      daysOfWeek = [
        "Monday",
        "Tuesday",
        "Wednesday",
        "Thursday",
        "Friday"
      ]

      rampUpStartTime = {
        hour   = 7,
        minute = 0
      },
      rampUpAutoStartHosts            = "None",
      rampUpStartVMOnConnect          = "Enable",
      rampUpMinutesToWaitOnDisconnect = 10,
      rampUpActionOnDisconnect        = "Hibernate",
      rampUpMinutesToWaitOnLogoff     = 10,
      rampUpActionOnLogoff            = "Hibernate",

      peakStartTime = {
        hour   = 8,
        minute = 0
      },
      peakStartVMOnConnect          = "Enable",
      peakMinutesToWaitOnDisconnect = 10,
      peakActionOnDisconnect        = "Hibernate",
      peakMinutesToWaitOnLogoff     = 10,
      peakActionOnLogoff            = "Hibernate",

      rampDownStartTime = {
        hour   = 16,
        minute = 30
      },
      rampDownStartVMOnConnect          = "Enable",
      rampDownMinutesToWaitOnDisconnect = 10,
      rampDownActionOnDisconnect        = "Hibernate",
      rampDownMinutesToWaitOnLogoff     = 10,
      rampDownActionOnLogoff            = "Hibernate",

      offPeakStartTime = {
        hour   = 17,
        minute = 30
      },
      offPeakStartVMOnConnect          = "Enable",
      offPeakMinutesToWaitOnDisconnect = 10,
      offPeakActionOnDisconnect        = "Hibernate",
      offPeakMinutesToWaitOnLogoff     = 10,
      offPeakActionOnLogoff            = "Hibernate",
    }
  })
}
