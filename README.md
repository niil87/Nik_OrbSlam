# Nik_OrbSlam

Welcome to this repository. This repository was created as an effort to support Research effort at Lund University. There are two bash script provided along with some support files to help with speeding up ORB-SLAM3 research efforts without need to worry about missing packages

The original files picked up from https://github.com/UZ-SLAMLab/ORB_SLAM3 and we thank the contributors for the original files. This repository contains fixes necessary for the packages to work on Ubuntu 20.04 as the original repository are either missing some files or some fixes.

The bash script "runMe.sh" installs all the packages in one go. Please note that this is a simple bash script and does not handle runtime error correction. It can only detect errors and will stop at point when an error is detected. By error I mean, program fails to run or installation failed, etc.

The second bash script "kalibrProc.sh" is to help with extraction of calibration related information required for generating the yaml files. 


## Requirement: 
Install Git on your station. Reference Link @ https://github.com/git-guides/install-git

## Steps to install ORB-SLAM3

### Clone the files from Github
```
git clone https://github.com/niil87/Nik_OrbSlam.git
```

### Go into the main directory and make a bash file an executable
```
cd Nik_OrbSlam/
chmod +x runMe.sh 
```

### Run the bash script file 
```
./runme.sh
```


## Steps for running Kalibr

### Calibration using tools provided by Intel
Prior to running this make, please make sure you have performed the necessary calibration on the device. We have used Intel Realsense D435i camera for performing ORB-SLAM3.

Almost any instrument that relies on sensors tends to degrade with time when subjected to either temperature variations or has undergone mobility [1]. It is empirical that we perform calibration before using the camera for data collection, the two important calibration procedures are summarized below. 

a.	Depth sensing: With degradation, we will observe bumpiness for flat surfaces or low fill ratio.  We use the tools provided by Intel and described in detail in [1]

b.	IMU sensing: With degradation, we will observe a high noise level in the measurements, non-zero bias, or cross-correlation in the axis. We use the python script provided by Intel and described in detail in [2]

### Calibration for obtaining Transformation matrix, camera calibration, distortion parameters, noise information, etc
Unfortunately, we couldnt automate the entire process; this includes generating the grid image file and capturing data + images for calibration using the grid image. We have listed down the steps needed to be performed prior to and while running "kalibrProc.sh" script. 

#### Generating April Grid
The link to downloading pregenerated grid images is broken. Assuming that you already installed necessary components via "Steps to install ORB-SLAM3" details listed above, you can use below command to navigate to kalibr_create_target_pdf script and run the necessary command to generate the custom april gril image file.  
```
## Navigate to location of kalibr_create_target_pdf file
cd /kalibr_workspace/devel/lib/kalibr

## Executing python script. Please provide approprite values for [NUM_COLS], [NUM_ROWS], [TAG_WIDTH_M], [TAG_SPACING_PERCENT]. (Eg 4,4,10,0.1)
python3 kalibr_create_target_pdf --type apriltag --nx [NUM_COLS] --ny [NUM_ROWS] --tsize [TAG_WIDTH_M] --tspace [TAG_SPACING_PERCENT]

## To return to main folder. The newly generated file april_grid.yaml will be located in same path as kalibr_create_target_pdf file.
cd ../../../..
```
If you are having difficulting generating the file, there is copy available at 
```
<Nik_Orbslam path>/supportFiles/april_grid.yaml
```
Please refer link @ https://github.com/ethz-asl/kalibr/wiki/calibration-targets for more details.

#### Running Kalibr bash script to perform file manipulation and keep the system ready for calibration files
```
chmod +x kalibrProc.sh 
./kalibrProc.sh
```


#### Setting up camera for data + image collection for calibration
Using new terminal window, we will use ros to capture data into bags, and process on bags later on. Before running "rosbag record", please make sure you are famaliar with camera movements as shown in https://www.youtube.com/watch?app=desktop&v=puNXsnrYWTY&ab_channel=SimpleKernel
```
## run roscore to initialize ros
roscore

## run below command in separate terminal for ros to latch on to the camera
roslaunch realsense2_camera rs_d435_camera_with_model_Nik.launch & 

## run below command to collect only necessary info for calibration
rosbag record /camera/depth/image_rect_raw /camera/depth/camera_info /camera/depth/metadata /camera/depth/color/points /camera/color/image_raw /camera/color/camera_info /camera/color/metadata /camera/infra1/image_rect_raw /camera/infra1/camera_info /camera/infra1/metadata /camera/infra2/image_rect_raw /camera/infra2/camera_info /camera/infra2/metadata /camera/gyro/imu_info  /camera/gyro/metadata  /camera/gyro/sample /camera/accel/imu_info /camera/accel/metadata /camera/accel/sample /tf -O Recording

## to view the contents of the bag after completion of data collection, use "rqt_bag" 
```

Once you are done with above steps, please hit enter on the terminal window that you used for running kalibrProc.sh

After collecting all the necessary files and performing calibration, a new set of yaml files will be generated and dispayed in terminal window display.




## References: 
[1] https://dev.intelrealsense.com/docs/self-calibration-for-depth-cameras

[2] https://www.intelrealsense.com/wp-content/uploads/2019/07/Intel_RealSense_Depth_D435i_IMU_Calibration.pdf

