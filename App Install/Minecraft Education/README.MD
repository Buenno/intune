# Minecraft Education

The Minecraft education installer is shipped as an EXE file which automatically creates a desktop shortcut on installation. As we do not want to create the desktop shortcuts, the .LNK file would need to be deleted post install. We are able to work around this by extracting the MSI installer form the EXE, building a transform file, and deploying the MSI. This allows us to stop the shortcut creation at the source. 

This application has a dependency on Visual C++ 2015, ensure this is deployed. 

## Extract the MSI
1. Execute the EXE installation file and wait until the automatic extraction is complete. 

2. Navigate to "C:\ProgramData\Microsoft Studios\Minecraft Education Edition\install". These are the files you will use within your deployment. 

If Microsoft decide to move the extraction directory for whatever reason then you can find the new location by monitoring the installation with Procmon.

## Transform
1. Open the MSI in Orca.

2. Create a new transform (Transform > New Transform).

3. Make your changes (Shortcuts table for desktop shortcut).

4. Generate the transform file (Transform > Generate Transform).

You can now apply your transform to the MSI using the msiexec parameter `TRANSFORM=generatedTransform.mst`.