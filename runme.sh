
AbortCheck() {
   if [ $? -ne 0 ]; then echo "Error in installation hence aborting"; exit /b 0; fi
}

a=1
if [ $a -eq 0 ]; then
    yes | sudo apt update
    yes | sudo apt install software-properties-common
    yes | sudo add-apt-repository ppa:deadsnakes/ppa
    yes | sudo apt update
    yes | sudo apt install python3.8


    # Getting number of processors to perform "make" faster
    Nproc=$(nproc)
    # To keep track of path
    Tpath=$(pwd)


    yes | sudo apt install git vim curl

    yes | sudo apt-get install cmake gcc g++ python3-dev python3-numpy python3-pip; AbortCheck

    # yes | sudo apt-get install libgtk-3-dev; AbortCheck

    


    # installing cv2

    yes | sudo apt install build-essential pkg-config libgtk-3-dev \
    libavcodec-dev libavformat-dev libswscale-dev libv4l-dev \
    libxvidcore-dev libx264-dev libjpeg-dev libpng-dev libtiff-dev \
    gfortran openexr libatlas-base-dev python3-dev python3-numpy \
    libtbb2 libtbb-dev libdc1394-22-dev libopenexr-dev \
    libgstreamer-plugins-base1.0-dev libgstreamer1.0-dev
    AbortCheck

    mkdir opencv_build && cd opencv_build
    git clone https://github.com/opencv/opencv.git
    git clone https://github.com/opencv/opencv_contrib.git

    cd opencv
    mkdir -p build && cd build

    cmake -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    -D INSTALL_C_EXAMPLES=ON \
    -D INSTALL_PYTHON_EXAMPLES=ON \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_EXTRA_MODULES_PATH=$Tpath/opencv_build/opencv_contrib/modules \
    -D BUILD_EXAMPLES=ON ..
    AbortCheck

    make -j$Nproc; AbortCheck

    sudo make install; AbortCheck

    cd $Tpath

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
    yes | sudo apt-get install libglew-dev libboost-dev libboost-thread-dev libboost-filesystem-dev libpython3-dev build-essential libeigen3-dev; AbortCheck
    
    git clone --recursive https://github.com/stevenlovegrove/Pangolin.git
    cd Pangolin
    mkdir -p build && cd build
    cmake ..; AbortCheck
    make -j$Nproc; AbortCheck
    
    cd $Tpath


    ## Eigen3 but this is already installed via pre-requisities in Pangolin 
    #yes | sudo apt install libeigen3-dev


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

    yes | sudo apt-get install ros-$ROS_DISTRO-realsense2-camera
    yes | sudo apt-get install ros-$ROS_DISTRO-realsense2-description

    yes | sudo apt-get install python3-rosdep
    sudo rosdep init
    rosdep update



    # ORB-SLAM related files
    sudo apt-get install -y libfmt-dev

    cd ORB_SLAM3
    chmod +x build.sh
    ./build.sh
    AbortCheck

    # Ros related build so we can run via rosrun for osb-slam3
    echo "export ROS_PACKAGE_PATH=${ROS_PACKAGE_PATH}:$Tpath/ORB_SLAM3/Examples/ROS" >> ~/.bashrc
    #source ~/.bashrc
    eval "$(cat ~/.bashrc | tail -n +10)"

    chmod +x build_ros.sh
    ./build_ros.sh
    AbortCheck

    cd ..

    # The EuroC Data set! Will take a long time to complete!
    wget -r --cut-dirs=1 -nH -np -R "index.html*" http://robotics.ethz.ch/~asl-datasets/ijrr_euroc_mav_dataset/machine_hall/MH_01_easy/

    yes | sudo apt-get install python3-setuptools python3-rosinstall libeigen3-dev libboost-all-dev doxygen libopencv-dev ros-noetic-vision-opencv ros-noetic-image-transport-plugins ros-noetic-cmake-modules python3-software-properties software-properties-common libpoco-dev python3-matplotlib python3-scipy python3-git python3-pip ipython3 libtbb-dev libblas-dev liblapack-dev python3-catkin-tools libv4l-dev python3-osrf-pycommon libsuitesparse-dev python3-dev python3-wxgtk4.0 python3-tk python3-igraph wget autoconf automake nano
    AbortCheck

    python3 -m pip install pyx; AbortCheck

    yes | sudo pip3 install pyrealsense2; AbortCheck


    # Kalibr files
    mkdir -p kalibr_workspace/src; AbortCheck

    cd kalibr_workspace/src; AbortCheck

    git clone https://github.com/ori-drs/kalibr.git --branch noetic-devel
    cd ..

    catkin build -DCMAKE_BUILD_TYPE=Release -j$Nproc; AbortCheck

    source ./devel/setup.bash
    echo "source $Tpath/kalibr_workspace/devel/setup.bash" >> ~/.bashrc

    #source ~/.bashrc
    eval "$(cat ~/.bashrc | tail -n +10)"

fi
