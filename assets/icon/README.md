# App icon sources

The Money Scribe launcher icon, drawn as SVG on a 108 × 108 canvas (Android
adaptive icon layout, foreground inside the 66 × 66 safe zone).

| File | Use |
| --- | --- |
| `ic_launcher_background.svg` / `.png` | Android adaptive icon background layer |
| `ic_launcher_foreground.svg` / `.png` | Android adaptive icon foreground layer |
| `ic_launcher_monochrome.svg` / `.png` | Android 13+ themed icon layer |
| `ios_icon_1024.svg` / `.png` | iOS icon, web icons and the legacy Android icon |

The SVG files are the sources. The PNG files are what `flutter_launcher_icons`
reads: 432 × 432 px for the Android layers (108 dp at xxxhdpi) and 1024 × 1024 px
for the square icon. They are not bundled in the app.

To change the icon, edit the SVG files, export the PNG files at the sizes above,
then regenerate the platform icons (configuration: `flutter_launcher_icons.yaml`):

```bash
dart run flutter_launcher_icons
```

The tool also changes two iOS files in ways that are wrong or unneeded. After
every run, restore them and remove the legacy icon sizes:

```bash
git checkout -- ios/Runner.xcodeproj/project.pbxproj ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json
rm ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-{50x50,57x57,72x72}@{1x,2x}.png
```
