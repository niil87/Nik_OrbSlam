
AbortCheck() {
   if [ $? -ne 0 ]; then echo "Error in installation hence aborting"; exit /b 0; fi
}

a=1
if [ $a -eq 0 ]; then
    sudo apt update
    sudo apt install software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt update
    yes | sudo apt install python3.8

    yes | sudo apt install git vim curl

    yes | sudo apt-get install cmake gcc g++ python3-dev python3-numpy python3-pip
    AbortCheck

    yes | sudo apt-get install libavcodec-dev libavformat-dev libswscale-dev
    AbortCheck

    yes | sudo apt-get install libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev
    AbortCheck

    yes | sudo apt-get install libgtk-3-dev
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

    python3 cv2_check.py
    exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        echo "in code"
        echo export PYTHONPATH="${PYTHONPATH}:/usr/local/lib/python3.8/site-packages" >> ~/.bashrc
        #source ~/.bashrc
        eval "$(cat ~/.bashrc | tail -n +10)"
        python3 cv2_check.py
        AbortCheck
    fi

    # installing librealsense
    sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE || sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-key F6E65AC044F831AC80A06380C8B3A55A6F3EFCDE
    
    sudo add-apt-repository "deb https://librealsense.intel.com/Debian/apt-repo $(lsb_release -cs) main" -u

    yes | sudo apt-get install librealsense2-dkms
    yes | sudo apt-get install librealsense2-utils
    yes | sudo apt-get install librealsense2-dev
    yes | sudo apt-get install librealsense2-dbg


    # Get Pangolin
    git clone --recursive https://github.com/stevenlovegrove/Pangolin.git
    cd Pangolin
    yes | ./scripts/install_prerequisites.sh recommended
    yes | cmake -B build
    AbortCheck
    cmake --build build
    AbortCheck
    cmake --build build -t pypangolin_pip_install
    AbortCheck
    cd ..


    # Eigen3 but this is already installed via pre-requisities in Pangolin 
    yes | sudo apt install libeigen3-dev


    # installing ros-neotic
    echo "deb http://packages.ros.org/ros/ubuntu focal main" | sudo tee /etc/apt/sources.list.d/ros-focal.list

    sudo apt-key adv --keyserver 'hkp://keyserver.ubuntu.com:80' --recv-key C1CF6E31E6BADE8868B172B4F42ED6FBAB17C654

    sudo apt update

    yes | sudo apt install ros-noetic-desktop-full

    source /opt/ros/noetic/setup.bash

    echo "source /opt/ros/noetic/setup.bash" >> ~/.bashrc

    #source ~/.bashrc
    eval "$(cat ~/.bashrc | tail -n +10)"


    # Verify Noetic installation
    Tpath=$(pwd)
    
    roscd
    
    File=temp.txt
    
    Tpath2=$(pwd)

    cd $Tpath

    echo $Tpath2 >> $File
    if grep -q 'noetic' "$File"; then
        echo "Success in executing roscd"
    else
        rm -rf temp.txt
        echo "Failure in executing roscd"; exit /b 0
    fi

    timeout 2s roscore >> $File
    if grep -q "started core service" "$File"; then
        echo "Success in executing roscore"
    else
        rm -rf temp.txt
        echo "Failure in executing roscore"; exit /b 0
    fi
    
    rm -rf temp.txt


    # ORB-SLAM related files
    sudo apt-get install -y libfmt-dev

    cd ORB_SLAM3
    chmod +x build.sh
    ./build.sh


fi

    cd ORB_SLAM3
    chmod +x build.sh
    ./build.sh

