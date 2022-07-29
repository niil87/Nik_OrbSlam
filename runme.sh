#!/bin/bash

AbortCheck() {
   if [ $? -ne 0 ]; then echo "Error in installation hence aborting"; exit /b 0; fi
}

a=1
if [ %a% = 0 ]; then
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update
    sudo apt install python3.8

    sudo apt install git vim curl

    sudo apt-get install cmake gcc g++ python3-dev python3-numpy
    AbortCheck

    sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev
    AbortCheck

    sudo apt-get install libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev
    AbortCheck

    sudo apt-get install libgtk-3-dev
    AbortCheck

    git clone https://github.com/opencv/opencv.git
    AbortCheck

    # installing cv2
    cd opencv
    mkdir build
    cd build
    cmake ../
    AbortCheck

    make
    AbortCheck

    sudo make install
    AbortCheck

    cd ..

fi

python3 cv2_check.py
exit_code=$?
if [[ $exit_code -ne 0 ]]; then 
    echo "in code"
    echo export PYTHONPATH="${PYTHONPATH}:/usr/local/lib/python3.8/site-packages" >> ~/.bashrc
    source ~/.bashrc
    python3 cv2_check.py
    echo $PYTHONPATH
    AbortCheck
fi
