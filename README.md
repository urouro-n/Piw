Piw
===

Web Browser iOS App for images  
Download on the [App Store](https://itunes.apple.com/jp/app/piw/id1249209151?mt=8)

## Getting Started

#### Copy files

```
$ cp Piw/BlackList.txt.example Piw/BlackList.txt
$ cp Piw/AppConfig.example.swift Piw/AppConfig.swift
$ cp Piw/Info.example.plist Piw/Info.plist
$ cp scripts/fabric.example.sh scripts/fabric.sh
```

#### Set up google services

- Install GoogleService-Info.plist
- Add to Piw/GoogleService-Info.plist

#### Carthage

```
$ carthage update --platform iOS
```
