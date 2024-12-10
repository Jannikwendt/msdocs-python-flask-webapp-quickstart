@description('Name of the Azure Container Registry')
param name string

@description('Location for the registry')
param location string = resourceGroup().location

@description('Enable admin user')
param acrAdminUserEnabled bool = true

resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: name
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: acrAdminUserEnabled
  }
}

output loginServer string = acr.properties.loginServer
output acrName string = acr.name
