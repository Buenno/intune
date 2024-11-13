# Arduino IDE 

This package installs the version 2 Typescript re-write of Arduino, not the version 1 Java edition.

This uses the system-wide MSI installer with a transform to remove the desktop shortcut, however the application writes user data to each users profile. 

Both the main application binary from the install directory and the mDNS-Discovery binary from within the user profile will prompt the current user to add a firewall exception on launching the application, we work around this by adding exceptions for both. As the mDNS-Discovery exe is located in each user profile, we add the firewall exception via a Powershell script which is executed at user logon (scheduled task). We also add the same rule for any existing users, however this is handled by the main Install-Application.ps1 script. 