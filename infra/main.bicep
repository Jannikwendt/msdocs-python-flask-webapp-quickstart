param location           string = ''westeurope''
param acrName            string = ''jwendtacr''
param planName           string = ''jwendt-asp''
param webName            string = ''jwendt-web''
param linuxSku           object = {
  capacity: 1
  family:   ''B''
  name:     ''B1''
  size:     ''B1''
  tier:     ''Basic''
}

module acr ''./modules/container-registry/main.bicep'' = {
  name: ''acr''
  params: {
    name:      acrName
    location:  location
    adminUserEnabled: true
  }
}

resource plan ''Microsoft.Web/serverfarms@2022-09-01'' = {
  name: planName
  location: location
  sku: linuxSku
  kind: ''linux''
  properties: {
    reserved: true     // Linux plan
  }
}

module web ''./modules/web/site/main.bicep'' = {
  name: ''web''
  params: {
    name:                 webName
    location:             location
    kind:                 ''app''
    serverFarmResourceId: plan.id
    siteConfig: {
      linuxFxVersion:  ''DOCKER|${acrName}.azurecr.io/placeholder:latest''
      appCommandLine:  ''''
    }
    appSettingsKeyValuePairs: {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE: false
      DOCKER_REGISTRY_SERVER_URL:  ''https://${acrName}.azurecr.io''
      DOCKER_REGISTRY_SERVER_USERNAME: acr.outputs.adminUsername
      DOCKER_REGISTRY_SERVER_PASSWORD: acr.outputs.adminPassword
    }
  }
  dependsOn: [acr]
}
