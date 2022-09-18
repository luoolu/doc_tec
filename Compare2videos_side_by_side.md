##  Compare two videos side by side using ffmpe

### Customise left.mp4, right.mp4 and ouput_leftRight.mp4
$  ffmpeg -i left.mp4 -i right.mp4 -filter_complex "[0:v:0]pad=iw*2:ih[bg]; [bg][1:v:0]overlay=w" ouput_leftRight.mp4

## Compare two video files by using a vertical split screen

ffmpeg -i input_file_1 -i input_file_2 -filter_complex "[0]crop=iw/2:ih:0:0[left];[1]crop=iw/2:ih:iw/2:0[right];[left][right]hstack[out]" -map "[out]" output_file





