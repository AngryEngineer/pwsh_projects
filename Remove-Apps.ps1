

# Remove superflous built-in applications
# Get-AppXProvisionedPackage -Online | Select PackageName
$targets = "*BingFinance*", "*BingNews*", "*BingSports*", "*BingWeather*", "*ZuneMusic*", "*ZuneVideo*", "*Messaging*", "*SkypeApp*", "*Office*", "*Sway*", "*ConnectivityStore*", "*windowscommunications*", "*A278AB0D*", "*king.com*"

$packages = Get-AppXProvisionedPackage -Online
foreach ($package in $packages) {
    foreach ($target in $targets) {
        if ($package.PackageName -like $target) {
            Write-Host "Deprovisioning package: ", $package.DisplayName
            Remove-AppXProvisionedPackage -Online -PackageName $package.PackageName
        }
    }
}



# Get-AppXPackage -AllUsers | Select PackageFullName
# list of application names to remove -- USE WILDCARD
$names = "*Sway*", "*3DBuilder*", "*ZuneVideo*", "*Advertising*", "*SkypeApp*", "*Office*", "*windowscommunications*" , "*BingSports*", "*BingWeather*", "*ConnectivityStore*", "*BingFinance*", "*BingNews*", "*ZuneMusic*", "*Messaging*", "*Twitter*", "*A278AB0D*", "*king.com*"
$apps = Get-AppXPackage -AllUsers
foreach ($app in $apps) {
    foreach ($name in $names) {
        if ($app.Name -like $name) {
            Write-Host "Removing app: ", $app.Name
            Remove-AppXPackage -Package $app
        }
    }
}
