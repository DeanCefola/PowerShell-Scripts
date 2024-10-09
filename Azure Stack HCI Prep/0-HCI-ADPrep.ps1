Install-Module AsHciADArtifactsPreCreationTool -Repository PSGallery -Force -Verbose







New-HciAdObjectsPreCreation `
    -Deploy `
    -AzureStackLCMUserCredential (Get-Credential) `
    -AsHciOUName "<NEW OU Distinguished Name>" `
    -AsHciPhysicalNodeList @("Node-0","Node-1","Node-2") `
    -DomainFQDN "<FQDN DOMAIN NAME>" `
    -AsHciClusterName "<Cluster NAME>" `
    -AsHciDeploymentPrefix "<PREFIX>"

    