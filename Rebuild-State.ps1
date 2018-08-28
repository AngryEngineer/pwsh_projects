$manifests = Get-ChildItem -Path "C:\Program Files\WindowsApps\*\AppxManifest.xml" -Recurse
$progress = $manifests.length

while ($manifests.length -gt 0) {
    foreach ($manifest in $manifests) {
        try {
            Add-AppxPackage -register $manifest.fullname -DisableDevelopmentMode
            $manifests.Remove($manifest)
            Write-Progress -Activity "Installing packages" -status $manifest -percentComplete ($manifests.length / $progress * 100) 
        }
        catch {
            Write-Host "Failed:"$manifest.fullname"\n"
        }
    
    }

}