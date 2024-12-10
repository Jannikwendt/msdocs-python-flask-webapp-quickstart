

param name string
param location string = resourceGroup().location
param kind string
param serverfarmsResourceId string
param siteConfig object
param appSettingsKeyValuePairs object

resource webApp 'Microsoft.Web/sites@2021-02-01' = {
  name: name
  location : location
  kind: kind
  properties : {
    serverFarmId : serverfarmsResourceId
    siteConfig: siteConfig
  }
}

resource WebAppSettings 'Microsoft.Web/sites/config@2021-02-01' = {
  parent: webApp
  name: 'appsettings'
  properties : appSettingsKeyValuePairs
}
