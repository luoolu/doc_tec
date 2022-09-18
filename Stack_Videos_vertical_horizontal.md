#   How to Stack Videos Horizontally using FFmpeg?

$ ffmpeg -i input0.mp4 -i input1.mp4 -filter_complex hstack=inputs=2 horizontal-stacked-output.mp4

#   Stacking Videos Vertically using FFmpeg

$ ffmpeg -i input0.mp4 -i input1.mp4 -filter_complex vstack=inputs=2 vertical-stack-output.mp4

#  2×2 Grid of Videos using FFmpeg

$ ffmpeg \
-i input0.mp4 -i input1.mp4 -i input2.mp4 -i input3.mp4 \
-filter_complex \
"[0:v][1:v]hstack=inputs=2[top]; \
[2:v][3:v]hstack=inputs=2[bottom]; \
[top][bottom]vstack=inputs=2[v]" \
-map "[v]" \
finalOutput.mp4

#  3×2 Grid of Videos using FFmpeg
$ ffmpeg \
-i input0.mp4 -i input1.mp4 \
-i input2.mp4 -i input3.mp4 \
-i input4.mp4 -i input5.mp4 \
-filter_complex \
"[0:v][1:v][2:v]hstack=inputs=3[top];\
[3:v][4:v][5:v]hstack=inputs=3[bottom];\
[top][bottom]vstack=inputs=2[v]" \
-map "[v]" \
finalOutput.mp4

#  Use the hstack filte to join images into one

-- 2 images:

$ ffmpeg -i a.jpg -i b.jpg -filter_complex hstack output.jpg

-- 3 images:

$ ffmpeg -i a.jpg -i b.jpg -i c.jpg -filter_complex "[0][1][2]hstack=inputs=3" output.jpg

----  If you want to vertically stack use vstack instead



##  Compare two videos side by side using ffmpe

### Customise left.mp4, right.mp4 and ouput_leftRight.mp4
$  ffmpeg -i left.mp4 -i right.mp4 -filter_complex "[0:v:0]pad=iw*2:ih[bg]; [bg][1:v:0]overlay=w" ouput_leftRight.mp4

## Compare two video files by using a vertical split screen

ffmpeg -i input_file_1 -i input_file_2 -filter_complex "[0]crop=iw/2:ih:0:0[left];[1]crop=iw/2:ih:iw/2:0[right];[left][right]hstack[out]" -map "[out]" output_file





