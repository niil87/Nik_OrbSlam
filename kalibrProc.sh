# Need to list how to get imu_intrinsics.yaml



AbortCheck() {
   if [ $? -ne 0 ]; then echo "Error in installation hence aborting"; exit /b 0; fi
}

sudo cp supportFiles/rs_d435_camera_with_model_Nik.launch  /opt/ros/${ROS_DISTRO}/share/realsense2_camera/launch/rs_d435_camera_with_model_Nik.launch

# Below cp of file with fixes are needed for reported issue link below
# https://github.com/ethz-asl/kalibr/issues/364
sudo cp supportFiles/MulticamGraph.py kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_camera_calibration/MulticamGraph.py

# Difficulty in running these process, so skipping 
#roscore &
#sleep 5

#roslaunch realsense2_camera rs_d435_camera_with_model_Nik.launch & 
#sleep 10

mkdir CalibrationInfo
cd CalibrationInfo


# Generate the GRID yaml file using reference : https://github.com/ethz-asl/kalibr/wiki/calibration-targets
# You need to provide the location of the calibration grid file, by default we have april grid file in supportFiles folder

echo "Enter Full path location of grid file used for calibration"
# /home/cnikh/Desktop/Git_Nikhil/Nik_OrbSlam/supportFiles/april_grid.yaml
read CALIBRATION_GRID
cp $CALIBRATION_GRID calibration_grid.yaml; AbortCheck


## Collect the bag using below command and the above yaml file 
# rosbag record /camera/depth/image_rect_raw /camera/depth/camera_info /camera/depth/metadata /camera/depth/color/points /camera/color/image_raw /camera/color/camera_info /camera/color/metadata /camera/infra1/image_rect_raw /camera/infra1/camera_info /camera/infra1/metadata /camera/infra2/image_rect_raw /camera/infra2/camera_info /camera/infra2/metadata /camera/gyro/imu_info  /camera/gyro/metadata  /camera/gyro/sample /camera/accel/imu_info /camera/accel/metadata /camera/accel/sample /tf -O Recording

# to view the bag, use "rqt_bag" 

echo "Enter Full path location of bag file containing calibration images"
# /home/cnikh/Desktop/Sample_Recording.bag
read BAG_LOC
cp $BAG_LOC Recording.bag; AbortCheck


# Info on RGB Camera
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_calibrate_cameras --bag Recording.bag --topics /camera/color/image_raw --models pinhole-radtan --target calibration_grid.yaml --dont-show-report

# Renaming for multiple calibrations
mv camchain-Recording.yaml Config_COLOR.yaml; AbortCheck
mv results-cam-Recording.txt Results_COLOR.txt; AbortCheck
mv report-cam-Recording.pdf Report_COLOR.pdf; AbortCheck

# Info on Infra Cameras
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_calibrate_cameras --bag Recording.bag --topics /camera/infra1/image_rect_raw /camera/infra2/image_rect_raw --models pinhole-radtan pinhole-radtan --target calibration_grid.yaml --dont-show-report

# Renaming for multiple calibrations
mv camchain-Recording.yaml Config_STEREO.yaml; AbortCheck
mv results-cam-Recording.txt Results_STEREO.txt; AbortCheck
mv report-cam-Recording.pdf Report_STEREO.pdf; AbortCheck


# We need to do a bit of data extraction due to way Kalibr works.. extracting gyro and accel data.
mkdir -p IMU_Data/IMU; AbortCheck
rostopic echo -b Recording.bag -p /camera/gyro/sample/header/stamp > IMU_Data/IMU/gyro_stamp.txt; AbortCheck
rostopic echo -b Recording.bag -p /camera/gyro/sample/angular_velocity > IMU_Data/IMU/gyro_info.txt; AbortCheck

rostopic echo -b Recording.bag -p /camera/accel/sample/header/stamp > IMU_Data/IMU/acc_stamp.txt; AbortCheck
rostopic echo -b Recording.bag -p /camera/accel/sample/linear_acceleration > IMU_Data/IMU/acc_info.txt; AbortCheck

#  No need to delete first line, we will process in python
# FILE=IMU_Data/IMU/gyro.txt
# tail -n +2 "$FILE" > "$FILE.tmp" && mv "$FILE.tmp" "$FILE"

mkdir -p IMU_Data/cam0
rostopic echo -b Recording.bag -p /camera/color/image_raw/header/stamp > IMU_Data/cam0/times_stamp.txt

# the script to fix the file format issue
python3 ../supportFiles/imu_bag_to_kalibr.py; AbortCheck
# script to generate the unified accel+gyro results
python3 ../ORB_SLAM3/Examples/Calibration/python_scripts/process_imu.py IMU_Data; AbortCheck
# Create bag with this IMU data and junk camera folder
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_bagcreater --folder IMU_Data --output-bag Bag_IMU_COLOR.bag

### I DONT SEE DIFFERENCE IN IMU INFO EVEN WHEN IMAGES ARE OF DIFFERENT TIME STAMP HENCE SKIPPING INFRA
## Same process for infra camera also, as the timing could be mismatch with color
# rostopic echo -b Recording.bag -p /camera/infra1/image_rect_raw/header/stamp > IMU_Data/cam0/times_stamp.txt
## script to generate the unified accel+gyro results
# python3 ../ORB_SLAM3/Examples/Calibration/python_scripts/process_imu.py IMU_Data
## Create bag with this IMU data and junk camera folder
# python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_bagcreater --folder IMU_Data --output-bag Bag_IMU_INFRA.bag



#Merging bags to simplify kalibr processing
wget https://www.clearpathrobotics.com/assets/downloads/support/merge_bag.py
python3 merge_bag.py RecordingFinal.bag Recording.bag Bag_IMU_COLOR.bag


# KEEP IN MIND THAT /imu0 the bag needs to be in specific format which is handled in previous steps
# Info on RGB + IMU
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_calibrate_imu_camera --bag RecordingFinal.bag --cam Config_COLOR.yaml --imu imu_intrinsics.yaml --target calibration_grid.yaml --dont-show-report

# Renaming for multiple calibrations
mv camchain-imucam-RecordingFinal.yaml Config_COLOR_IMU.yaml
mv imu-RecordingFinal.yaml Config_IMU.yaml
mv results-imucam-RecordingFinal.txt Results_COLOR_IMU.txt
mv report-imucam-RecordingFinal.pdf Report_COLOR_IMU.pdf


# Info on INFRA + IMU
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_calibrate_imu_camera --bag RecordingFinal.bag --cam Config_INFRA.yaml --imu imu_intrinsics.yaml --target calibration_grid.yaml --dont-show-report

# Renaming for multiple calibrations
mv camchain-imucam-RecordingFinal.yaml Config_INFRA_IMU.yaml
rm -rf imu-RecordingFinal.yaml   # duplicate hence not required
mv results-imucam-RecordingFinal.txt Results_INFRA_IMU.txt
mv report-imucam-RecordingFinal.pdf Report_INFRA_IMU.pdf


### Files we dont need
## Config_COLOR.yaml and Config_IMU.yaml exist in Config_COLOR_IMU.yaml
# rm -rf Config_RGB.yaml
## Config_IMU.yaml exist in imu_intrinsics.yaml
# rm -rf Config_IMU.yaml
## Config_INFRA.yaml exist in Config_INFRA_IMU.yaml
# rm -rf Config_INFRA.yaml
