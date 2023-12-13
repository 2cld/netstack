[edit](https://github.com/2cld/netstack/edit/master/docs/portals/plex/rust-api/README.md)

placeholder for possible rust-api

- [Plex install](https://support.plex.tv/articles/200288586-installation/)
- [Plex-api - plexapi.dev](https://plexapi.dev/docs/plex-tv/get-devices)
- [tbd]()
- [plex-api - creates.io](https://crates.io/crates/plex-api/0.0.3)
- [plex-api - python original](https://github.com/pkkid/python-plexapi/tree/master)

Recording test using silicon dust and vlc

- [http://192.168.6.11/](http://192.168.6.11/) - cf local silicondust tuner
- [http://192.168.6.11/lineup.html](http://192.168.6.11/lineup.html) - tuner lineup
- [http://192.168.6.11:5004/auto/v2.1](http://192.168.6.11:5004/auto/v2.1) - ts stream for chanel 2.1
- Open VLC
- Open Capture Device - Network
  - URL http://192.168.6.11:5004/auto/v2.1
  - Check Stream Output
  - Open Settings
  - Display Stream locally
  - File: /Users/cat/Documents/VLC-SiliconDustTestRecord.ts
  - Encapsulation: MPEG TS (or what-ever you want to use)
