[edit](https://github.com/2cld/netstack/edit/master/docs/portals/streamstudio/README.md)

### Simple Edit [lossless-cut - tutorials](https://www.youtube.com/@tutortube/search?query=lossless-cut)
- [lossless-cut - github download](https://github.com/mifi/lossless-cut)
- [LossLessCut Tutorial - Lesson 17 - Merge Cuts](https://www.youtube.com/watch?v=_4m5IEBFyfE)
- [LossLessCut Tutorial - Lesson 18 - Merging Videos](https://www.youtube.com/watch?v=BLIwnjLQLpg)

# OBS
## OBS Sound Sync
- click cog next to audio source
- set audio delay

# Blender
- [ffmpeg tutorial](https://www.youtube.com/watch?v=MPV7JXTWPWI)
- [ffmpeg cut splice](https://superuser.com/questions/377343/cut-part-from-video-file-from-start-position-to-end-position-with-ffmpeg)
- [ffmpeg docs](https://ffmpeg.org/ffmpeg.html)
- [ffmpeg seeking](https://trac.ffmpeg.org/wiki/Seeking#Cuttingsmallsections)
- [ffmpeg split](https://youtu.be/Ij-IA24U6r8?t=228)
  ```
  ffmpeg -i "video.mp4" -c copy -map 0 -segment_time 00:05:00 -f segment -reset_timestamps 1 output%03d.mp4
  ```

## Blender Video Edit
- Open Blender
- File -> New -> Video Editing (or add new tab)
- Open video source files
- Set Output Properties (right vertical tabs) [youtube](https://youtu.be/1OpbKMSN61o?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=266)
  - Format - Res X:1920 Y:1080 %:100 Aspect X:1.000 Y:1.000 Frame Rate 24 fps
  - Frame Range
  - Output - Select output folder FileFormat: FFmpeg Video RGB
  - Encoding - Audio Codec: AAC
- Timeline [youtube](https://youtu.be/1OpbKMSN61o?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=448)
  - Sequencer Timeline
  - Framerate must match video file
- Load file drag and drop file into timeline
  - Framerate will auto adjust to first video imported
  - Handbreak can convert framerates if you need it
  - Blender will build proxies so you can scrub, X will stop the job if you dont want to wait
- Basic Rendering [youtube](https://youtu.be/1OpbKMSN61o?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=808)
  - Bars on bottom and side can zoom and pan
  - Select and Delete tracks (Ctrl D)
  - Select both (drag box or click) Drag to timeline
  - Copy paste frame count to End Frame in start-end
  - Set start-end before render
  - Render -> Render Animation2
- Basic Editing [youtube](https://youtu.be/nKBB0BLXbw0?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY)
  - Soft Cuts or Splits K [youtube](https://youtu.be/nKBB0BLXbw0?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=13)
    - Select files to cut, set time cursor, K (or right click Split) will split the file (soft cut)
    - soft cut allows you to adjust the ends
    - Control click so you can select both edges and move to shrink or extend Ctrl Z to undo
  - Hard Cuts or Hold Split Shift K [youtube](https://youtu.be/nKBB0BLXbw0?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=115)
    - need to use hard cut to change speed
  - FF / slow mo [youtube](https://youtu.be/nKBB0BLXbw0?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=223)
  - Rotatae / Pan / Scene in Scene [youtube](https://youtu.be/nKBB0BLXbw0?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=281)
  - Effects [youtube](https://youtu.be/nKBB0BLXbw0?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=539)
  - Transitions [youtube](https://youtu.be/5WhlRQky90w?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY)
  - Remove gaps [youtube](https://youtu.be/5WhlRQky90w?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=235)
    - put time cursor in video
    - Press Backspace (not Delete, apple does not have backspace) all spaces forward in time will be collapsed
  - Crossfade [youtube](https://youtu.be/5WhlRQky90w?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=311)
  - Demo Render [youtube](https://youtu.be/5WhlRQky90w?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY&t=537)
    - Set start and end point
    - Render -> Render Animation

## Blender Video Edit
- Blender [GPU enable](https://docs.blender.org/manual/en/latest/render/cycles/gpu_rendering.html)
  - Preferences -> System -> Cycles -> Cuda
  - Use defaults, but Video Sequencer
    - Memory Cache Limit 6000
    - Disk Cache Checked
    - Cache Limit 100
    - Compression None
    - Proxy Automatic
- [Blender Video Editing Tutorial](https://www.youtube.com/playlist?list=PLalVdRk2RC6qo7oHp5OO8e7RMe46nYdOY)
- Issue with file permissions
- 

### Config Notes
- Verify GPU in chrome
- chrome://settings/ -> System -> Use hardware acceleration when available
- Windows 11 -> System -> Display -> Graphics -> Add App (Chrome, OBS, Blender)
- tbd

### Reference
- [old streamstudio](./history) from https://raw.githubusercontent.com/christrees/blog/master/wip/streamstudio.md
