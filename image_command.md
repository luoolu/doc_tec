# -*- coding: utf-8 -*-
# @Time    : 2021/8/12 上午9:04
# @Author  : Luo Lu
# @Email   : argluolu@gmail.com
# @File    : images_command.py
# @Software: PyCharm

## batch convert grayscale to RGB color
mogrify -type TrueColor *.png
mogrify -type TrueColor *.jpg

## single convert grayscale to RGB color
mogrify  -colorspace Gray yourpic.jpg

##  pngs to jpg
mogrify -format jpg filename.jpg

##  pngs to mp4
ffmpeg -r 1/7 -i c%dm04_1.png -c:v libx264 -vf fps=1 -pix_fmt yuv420p -vf pad="width=ceil(iw/2)*2:height=ceil(ih/2)*2" out.mp4

ffmpeg -framerate 25 -pattern_type glob -i "*.png" out.mp4
### each image stays for N seconds, you can add the -r option followed by a value of 1/N.
ffmpeg -framerate 1/N -pattern_type glob -i "*.png" -r 25 out.mp4


##  Video split and restore
# ffmpeg -framerate 30.00 -pattern_type glob -i '*.jpg' -c:v libx264 -r 30 -pix_fmt yuv420p jdd_video.mp4
# ffmpeg -i video.mp4 -i audio.wav -c:v copy -c:a aac output.mp4

## Extracting mp3 from mp4
ffmpeg -i input.mp4 -map 0:a output.mp3

## Insert frame into video
ffmpeg -i need_process_video.mp4 -loop 1 -i insert_frame.png -filter_complex "[0][1]overlay=enable='if(gt(n,0),not(mod(n,20)),0)':shortest=1[v]" -map "[v]" -map 0:a -c:a copy out.mp4


## convert avi to mp4
 ffmpeg -i infile.avi youroutput.mp4
 
## speed mp4 to gif or mp4
ffmpeg -i Rec0001.mp4 -filter:v "setpts=0.15*PTS" -r 30 lubs12.gif
ffmpeg -i input.mp4 -filter:v "setpts=0.15*PTS" -r 30 output.mp4

## speed up gif
convert -delay 1x30 input.gif input-fast.gif

## slow down gif
convert -delay 1x100 input.gif input-slow.gif

## clip video
avconv -i *.mp4 -c:a copy -c:v copy -ss hh:mm:ss -t 00:0m:ss output.mp4
avconv -i Rec\ 0001.mp4 -c:a copy -c:v copy -ss 00:00:07 -t 00:01:34 c7001.mp4

## rescale video
avconv -i input.mp4 -s 640x480 output.mp4

## How to concatenate two MP4 files using FFmpeg?
$ cat mylist.txt
file '/path/to/file1'
file '/path/to/file2'
file '/path/to/file3'
    
$ ffmpeg -f concat -safe 0 -i mylist.txt -c copy output.mp4

## resize an animated GIF file using ImageMagick?
gifsicle input.gif --resize 50x50 > resized.gif

## loop play mp4 
mplayer -fs -loop 0 video.mp4 

## batch processing tif images--converting tif to jpg
mogrify -format jpg *.tif  (have installed ImageMagic)

cd into the directory where your tif files are.
then:
for f in *.tif; do  echo "Converting $f"; convert "$f"  "$(basename "$f" .tif).jpg"; done

for f in *.tif
do  
    echo "Converting $f" 
    convert "$f"  "$(basename "$f" .tif).jpg" 
done














