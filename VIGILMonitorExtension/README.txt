VIGIL — Device Activity Monitor extension

1. In Xcode: File → New → Target → Device Activity Monitor Extension.
2. Name it VIGILMonitorExtension (or keep default) and set bundle id com.ayush.vigil.VIGIL.monitor.
3. Delete the template Swift file Xcode generates; add VigilDeviceActivityMonitor.swift from this folder to the new target.
4. Set the extension’s Info.plist NSExtension → NSExtensionPointIdentifier to
   com.apple.deviceactivity.monitor-extension
5. Add the same App Group capability as the main app: group.com.ayush.vigil.VIGIL
6. To receive violation events during a block, register DeviceActivityEvent maps in ScreenTimeManager
   when ApplicationTokens from FamilyActivityPicker are available.
