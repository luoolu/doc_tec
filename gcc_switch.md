## Installing GCC and G++ compilers on Ubuntu 22.04 step by step instruction\

$ sudo apt update \
$ sudo apt install build-essential \
$ sudo apt -y install gcc-8 g++-8 gcc-9 g++-9 gcc-10 g++-10 \
\
## Use the update-alternatives tool to create list of multiple GCC and G++ compiler alternatives:\

$ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 8 \
$ sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-8 8 \
$ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9 \
$ sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9 \
$ sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 10 \
$ sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 10 \

## Check the available C and C++ compilers list on your Ubuntu 22.04 system and select desired version by entering relevant selection number: \

$ sudo update-alternatives --config gcc \
There are 3 choices for the alternative gcc (providing /usr/bin/gcc). \
 \
  Selection    Path            Priority   Status \
------------------------------------------------------------ \
  0            /usr/bin/gcc-9   9         auto mode 
  1            /usr/bin/gcc-10  10         manual mode 
* 2            /usr/bin/gcc-8   8         manual mode 
  3            /usr/bin/gcc-9   9         manual mode 
Press  to keep the current choice[*], or type selection number:  











