// app-service-plan.bicep

param name string
param location string = resourceGroup().location
param sku object

resource appServicePlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: name
  location: location
  sku: sku
  kind: 'Linux'
  properties: {
    reserved: true
  }
}

output planId string = appServicePlan.id
