## batch convert .wmv file to .mp4 file

$ mkdir output
$ for f in *.wmv; do ffmpeg -i "$f" -c:v libx264 -crf 18 -c:a aac "output/${f%.wmv}.mp4"; done

## single convert wmv to mp4

### Install ffmpeg

$ sudo apt-get install ffmpeg
### Convert files like this

$ ffmpeg -i input.wmv -s size output.mp4
    hd480
           852x480

       hd720
           1280x720

       hd1080
           1920x1080
