# Wallpaper   

### About
This app downloads and configures desktop and lockscreen wallpapers. I found that the "normal" Intune way of applying wallpapers would not apply the settings until the 2nd user login, which isn't really good enough. 

* Identifies primary display aspect ratio 
* Downloads appropriate wallpapers from Azure container
* Downloaded wallpapers apply to all users
* Reapplies default wallpapers once app is uninstalled

### Signing Scripts

Please note that the installation script utilises code which will not run in Constrained Language Mode, therefore the script will need to be signed if using App Control with script enforcement. 

Once you've install your code signing cert, store it in a variable with `$cert = Get-ChildItem Cert:\CurrentUser\My -CodeSigningCert`.

You can then sign your scripts with `Set-AuthenticodeSignature -Certificate $cert -FilePath .\Set-Wallpaper.ps1`.

You can then proceed with building your .intunewin package as normal.
 