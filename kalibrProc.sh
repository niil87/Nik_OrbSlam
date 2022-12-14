# Need to list how to get imu_intrinsics.yaml



AbortCheck() {
   if [ $? -ne 0 ]; then echo "Error in Calibration process hence aborting. If you see a failure to converge in optimization [Optimization diverged possibly due to a bad initialization], please rerun"; exit /b 0; fi
}

# this is to disable the emitter (for depth sensing) to avoid dots on screen during collection of calibration images. 
# this line was added to original file "rs_d435_camera_with_model.launch" : <rosparam> /camera/stereo_module/emitter_enabled: 0 </rosparam>
sudo cp supportFiles/rs_d435_camera_with_model_Nik.launch  /opt/ros/${ROS_DISTRO}/share/realsense2_camera/launch/rs_d435_camera_with_model_Nik.launch

# Below cp of file with fixes are needed for reported issue link below
# https://github.com/ethz-asl/kalibr/issues/364
sudo cp supportFiles/MulticamGraph.py kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_camera_calibration/MulticamGraph.py


## Need to handle issue : https://github.com/ethz-asl/kalibr/issues/448
## And https://stackoverflow.com/questions/8515053/csv-error-iterator-should-return-strings-not-bytes
sudo cp supportFiles/kalibr_bagcreater kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_bagcreater

echo "Automated collection of images and data for calibration is commented out, please perform steps manually. Hit enter when done with manual steps"
read ENTER_CMD
####################################################################################################
# Difficulty in running these process, so skipping collection of calibration images via script
#roscore &

#roslaunch realsense2_camera rs_d435_camera_with_model_Nik.launch & 

# Generate the GRID yaml file using reference : https://github.com/ethz-asl/kalibr/wiki/calibration-targets
# You need to provide the location of the calibration grid file, by default we have april grid file in supportFiles folder

## Collect the bag using below command and the above yaml file 
# rosbag record /camera/depth/image_rect_raw /camera/depth/camera_info /camera/depth/metadata /camera/depth/color/points /camera/color/image_raw /camera/color/camera_info /camera/color/metadata /camera/infra1/image_rect_raw /camera/infra1/camera_info /camera/infra1/metadata /camera/infra2/image_rect_raw /camera/infra2/camera_info /camera/infra2/metadata /camera/gyro/imu_info  /camera/gyro/metadata  /camera/gyro/sample /camera/accel/imu_info /camera/accel/metadata /camera/accel/sample /tf -O Recording

# to view the bag, use "rqt_bag" 
####################################################################################################

## removing any older files under CalibrationInfo folder as it interrupts the process sometimes.
rm -rf CalibrationInfo

mkdir CalibrationInfo
cd CalibrationInfo


echo "Enter Full path location of grid file (eg. april_grid.yaml) used for calibration"
# ../supportFiles/april_grid.yaml
read CALIBRATION_GRID
cp $CALIBRATION_GRID calibration_grid.yaml; AbortCheck


echo "Enter Full path location of bag file containing calibration images"
# ../../Desktop/Recording.bag  ## unfortunately I cannot keep this file in GIT as its too big in size.
read BAG_LOC
cp $BAG_LOC Recording.bag; AbortCheck



## NEED WAY OR INFO TO GET imu_intrinsics.yaml
cp ../supportFiles/imu_intrinsics.yaml imu_intrinsics.yaml

## Custome yaml file to ensure ORBextractor and Viewer parameters are updated for all files accurately
cp ../supportFiles/ORBex_and_Viewer.yaml ORBex_and_Viewer.yaml




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

# the script to fix the file format issue that Kalibr is expecting before creating bag file
python3 ../supportFiles/imu_bag_to_kalibr.py; AbortCheck
# script to generate the unified accel+gyro results
python3 ../ORB_SLAM3/Examples/Calibration/python_scripts/process_imu.py IMU_Data; AbortCheck
# Create bag with this IMU data (camera folder has no significance)
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_bagcreater --folder IMU_Data --output-bag Bag_IMU_COLOR.bag; AbortCheck


### I DONT SEE DIFFERENCE IN IMU INFO EVEN WHEN IMAGES ARE OF DIFFERENT TIME STAMP HENCE SKIPPING INFRA
## Same process for infra camera also, as the timing could be mismatch with color
# rostopic echo -b Recording.bag -p /camera/infra1/image_rect_raw/header/stamp > IMU_Data/cam0/times_stamp.txt; AbortCheck
## script to generate the unified accel+gyro results
# python3 ../ORB_SLAM3/Examples/Calibration/python_scripts/process_imu.py IMU_Data; AbortCheck
## Create bag with this IMU data and junk camera folder
# python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_bagcreater --folder IMU_Data --output-bag Bag_IMU_INFRA.bag; AbortCheck



#Merging bags to simplify kalibr processing
wget https://www.clearpathrobotics.com/assets/downloads/support/merge_bag.py; AbortCheck
python3 merge_bag.py RecordingFinal.bag Recording.bag Bag_IMU_COLOR.bag; AbortCheck



# https://github.com/ethz-asl/kalibr/wiki/Camera-IMU-calibration
# KEEP IN MIND THAT /imu0 the bag needs to be in specific format which is handled in previous steps
# Info on RGB + IMU
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_calibrate_imu_camera --bag RecordingFinal.bag --cam Config_COLOR.yaml --imu imu_intrinsics.yaml --target calibration_grid.yaml --dont-show-report; AbortCheck

# Renaming for multiple calibrations
mv camchain-imucam-RecordingFinal.yaml Config_COLOR_IMU.yaml; AbortCheck
mv imu-RecordingFinal.yaml Config_IMU.yaml; AbortCheck
mv results-imucam-RecordingFinal.txt Results_COLOR_IMU.txt; AbortCheck
mv report-imucam-RecordingFinal.pdf Report_COLOR_IMU.pdf; AbortCheck


# Info on INFRA + IMU
python3 ../kalibr_workspace/src/kalibr/aslam_offline_calibration/kalibr/python/kalibr_calibrate_imu_camera --bag RecordingFinal.bag --cam Config_STEREO.yaml --imu imu_intrinsics.yaml --target calibration_grid.yaml --dont-show-report

# Renaming for multiple calibrations
mv camchain-imucam-RecordingFinal.yaml Config_STEREO_IMU.yaml; AbortCheck
rm -rf imu-RecordingFinal.yaml   # duplicate hence not required
mv results-imucam-RecordingFinal.txt Results_STEREO_IMU.txt; AbortCheck
mv report-imucam-RecordingFinal.pdf Report_STEREO_IMU.pdf; AbortCheck


### Some files we dont need as we have superset files
# Config_COLOR.yaml and Config_IMU.yaml exist in Config_COLOR_IMU.yaml
rm -rf Config_COLOR.yaml
# Config_IMU.yaml exist in imu_intrinsics.yaml
rm -rf Config_IMU.yaml
# Config_STEREO.yaml exist in Config_STEREO_IMU.yaml
rm -rf Config_STEREO.yaml


## Relying on METADATA to get the fps
## There is an issue with color running at 30fps, need to retest with 20fps
rostopic echo -b Recording.bag -p /camera/color/metadata -n 1 > metadata_color.txt  # color seems to be running at slightly lower fps!! even after launch file was correctly configured!
rostopic echo -b Recording.bag -p /camera/infra1/metadata -n 1 > metadata_infra.txt


## Final script to overwrite fields in yaml files to be used by orb-slam based on kalibr results.
python3 ../supportFiles/kalibr_to_orbslam_yaml.py ../ORB_SLAM3; AbortCheck




