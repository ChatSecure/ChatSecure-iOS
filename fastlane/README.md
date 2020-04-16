fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
## Mac
### mac test
```
fastlane mac test
```
Runs tests on macOS
### mac release
```
fastlane mac release
```
Submit a new macOS release

----

## iOS
### ios test
```
fastlane ios test
```
Runs tests on iOS
### ios release
```
fastlane ios release
```
Submit a new iOS release
### ios screenshots
```
fastlane ios screenshots
```
Generate new localized screenshots
### ios upload_screenshots
```
fastlane ios upload_screenshots
```
Uploads screenshots to iTC
### ios upload_metadata
```
fastlane ios upload_metadata
```
Uploads metadata to iTC
### ios upload_all
```
fastlane ios upload_all
```
Uploads metadata and screenshots to iTC

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
