// infra/main.bicep
// ────────────────────────────────────────────────
param location string  = 'westeurope'
param acrName  string  = 'jwendtacr'
param planName string  = 'jwendt-asp'
param webName  string  = 'jwendt-web'

var linuxSku = {
  name:     'B1'
  tier:     'Basic'
  size:     'B1'
  family:   'B'
  capacity: 1
}

//
// Azure Container Registry
//
resource acr 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: true
  }
}

//
// Linux App Service plan
//
resource plan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: linuxSku
  properties: {
    reserved: true  // Linux plan
  }
}

//
// Web App for Containers
//
resource web 'Microsoft.Web/sites@2022-09-01' = {
  name: webName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: plan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acrName}.azurecr.io/placeholder:latest'
      appSettings: [
        {
          name:  'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name:  'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${acrName}.azurecr.io'
        }
        {
          name:  'DOCKER_REGISTRY_SERVER_USERNAME'
          value: acr.listCredentials().username
        }
        {
          name:  'DOCKER_REGISTRY_SERVER_PASSWORD'
          value: acr.listCredentials().passwords[0].value
        }
      ]
    }
  }
}
