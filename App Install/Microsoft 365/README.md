## Microsoft 365

This installation script uses the [office deployment tool](https://learn.microsoft.com/en-us/microsoft-365-apps/deploy/overview-office-deployment-tool) and associated configuration files for installing and uninstalling the required office applications.

You will need to download the most recent binary for this tool and drop it into the binary directory. You may also need to [recreate the install.xml file](https://config.office.com/deploymentsettings) if it becomes outdated (unsupported by setup.exe)

The company name has been removed from the install.xml file, you'll need to add these before packaging with IntuneWinAppUtil.exe.

If the software fails to install, change the display level in the install xml to "FULL", this will result in a UI during install which will display any errors. 