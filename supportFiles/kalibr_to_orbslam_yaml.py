### Pending work
## 1. distortion for fish eye, etc needs addition @ https://github.com/ethz-asl/kalibr/wiki/supported-models
## 2. camera types refer to @ https://github.com/ethz-asl/kalibr/wiki/yaml-formats / https://github.com/ethz-asl/kalibr/wiki/supported-models


import yaml
from yaml import SafeLoader,SafeDumper
import cv2
import numpy as np
import codecs
import os
import sys
import argparse
import re


# Sample command line string after making sure you cd to ORB_SLAM3 folder
# python3 kalibr_to_orbslam_yaml.py <path to ORB_SLAM3>

parser = argparse.ArgumentParser(description='Generating YAML files')
parser.add_argument('path', type=str, help='path to ORB-SLAM3 folder')
args = parser.parse_args()
orbslam_path = args.path

print(orbslam_path)

k2o_hash = {"pinhole" : "PinHole", "rectified" : "Rectified"}

commentHash = {"IMU.T_b_c1" : "\n# Transformation from body-frame (imu) to left camera\n", 
               "File.version" : "\n#--------------------------------------------------------------------------------------------\n# Camera Parameters. Adjust them!\n#--------------------------------------------------------------------------------------------\n", 
               "Camera.type" : "\n",
               "Camera1.fx" : "\n# Camera1 (D435i : Infra1 if Mono or Stereo or RGB if RGB-D) Calibration Parameters (OpenCV)\n",
               "Camera1.k1" : "\n# Camera1 (D435i : Infra1 if Mono or Stereo or RGB if RGB-D) Distortion Parameters\n",
               "Camera2.fx" : "\n\n# Camera2 (D435i : Infra2 for Stereo) Calibration Parameters (OpenCV)\n",
               "Camera2.k1" : "\n# Camera2 (D435i : Infra2 for Stereo) Distortion Parameters\n",
               "Camera.width" : "\n\n# Camera resolution\n",
               "Camera.fps" : "\n# Camera frames per second\n",
               "Camera.RGB" : "\n# Color order of the images (0: BGR, 1: RGB. It is ignored if images are grayscale)\n",
               "Stereo.ThDepth" : "\n# Close/Far threshold. Baseline times.\n",
               "Stereo.b" : "\n",
               "RGBD.DepthMapFactor" : "\n# Depth map values factor\n",
               "ORBextractor.nFeatures" : "\n\n#--------------------------------------------------------------------------------------------\n# ORB Parameters [May require fine tuning depending on features in image]\n#--------------------------------------------------------------------------------------------\n# ORB Extractor: Number of features per image\n",
               "ORBextractor.scaleFactor" : "\n# ORB Extractor: Scale factor between levels in the scale pyramid\n",
               "ORBextractor.nLevels" : "\n# ORB Extractor: Number of levels in the scale pyramid\n",
               "ORBextractor.iniThFAST" : "\n# ORB Extractor: Fast threshold\n# Image is divided in a grid. At each cell FAST are extracted imposing a minimum response.\n# Firstly we impose iniThFAST. If no corners are detected we impose a lower value minThFAST\n# You can lower these values if your images have low contrast\n",
               "Viewer.KeyFrameSize" : "\n\n#--------------------------------------------------------------------------------------------\n# Viewer Parameters [only for the viewer generated while running orbslam, does not modify results]\n#--------------------------------------------------------------------------------------------\n",
               "IMU.T_b_c1" : "\n# Transformation from body-frame (imu) to left camera\n",
               "Stereo.T_c1_c2" : "\n# (D435i : Stereo : Infra1 to Infra2) Traslation matrix\n",
               "IMU.NoiseGyro" : "\n\n# IMU noise (Default : Intel Realsense D435i)\n# NoiseGyro unit : rad/s^0.5\n",
               "IMU.NoiseAcc" : "# NoiseAcc unit : m/s^1.5\n",
               "IMU.GyroWalk" : "# GyroWalk unit : m/s^1.5\n",
               "IMU.AccWalk" : "# AccWalk unit : m/s^2.5\n",
               "IMU.InsertKFsWhenLost" : "\n# Do not insert KFs when recently lost\n",
               "IMU.Frequency" : "# Frequency unit : info/s\n" }

def FixMatrix(File) :
	f2 = open("Copy.yaml", "w")
	f1 = open(File,"r") 

	while True :
		line = f1.readline()
		if not line:
			break

		if "data:" in line:
			text = "  " + line.strip() + " ["
			for i in range(16):
				line = f1.readline()
				line = (line.strip())[2:]
				text = text + line + ","
				if i == 15:
					text = text[:-1] + "]\n"
				elif ((i+1)%4 == 0):
					text = text + "\n         "
			f2.write(text)
		else :
			f2.write(line)

	f1.close()
	f2.close()
	os.system("cp " + "Copy.yaml" + " " + File)


def CreateYaml(SourceFile, Dict, TargetFile) :
	os.system("cp " + SourceFile + " " + "Copy.yaml")
	SourceFile = "Copy.yaml"
	fs2 = cv2.FileStorage(SourceFile, cv2.FILE_STORAGE_READ)
	root = fs2.root()

	yaml_file = codecs.open(TargetFile, mode="w", encoding="utf-8")
	yaml_file.write("%YAML:1.0\n")

	Dest3 = {}
	for name in root.keys():
		model = root.getNode(name)
		if (model.type() == 3) :  # string
		    Dest3[name] = model.string()
		elif (model.type() == 2) : # real
		    Dest3[name] = float(model.real())
		elif (model.type() == 1) : # int  
		    Dest3[name] = int(model.real())   # not able to find an integer variant of function!!
		elif (model.type() == 5) : # seq/matrix
		    Dest3[name] = model.mat()
		else :
		    print("Type not considered, need rework!!")
		    exit()

		if name in Dict.keys() :
		    Dest3[name] = Dict[name]

		if name in commentHash.keys() :
			yaml_file.write(commentHash[name])
			
		yaml.dump({name:Dest3[name]},yaml_file,default_flow_style=False,allow_unicode=True,sort_keys=False)


def IdentifyKeys(SourceFile,Dict) :
	fs1 = yaml.load(open(SourceFile),Loader=yaml.Loader)  
	cam_indx = 0;
	for k,v in fs1.items() :
		# this index is to be used while overwriting target level objects 
		# [https://idratherbewriting.com/learnapidoc/pubapis_yaml.html]
		if re.match(r"cam[0-9]+",k) :
			cam_indx = cam_indx + 1
			for kc in v :
				if (kc == "T_cam_imu") :
				    tempS = "IMU.T_b_c" + str(cam_indx)
				    A = np.array(fs1[k][kc])
				    B = np.linalg.inv(A)
				    Dest[tempS] = B
				elif (kc == "camera_model") :
					tempS = "Camera.type"
					Dest[tempS] = k2o_hash[fs1[k][kc]]
				elif (kc == "distortion_coeffs") : 
					tempS = "Camera" + str(cam_indx) + ".k1"
					Dest[tempS] = fs1[k][kc][0]
					tempS = "Camera" + str(cam_indx) + ".k2"
					Dest[tempS] = fs1[k][kc][1]
					tempS = "Camera" + str(cam_indx) + ".p1"
					Dest[tempS] = fs1[k][kc][2]
					tempS = "Camera" + str(cam_indx) + ".p2"
					Dest[tempS] = fs1[k][kc][3]
				elif (kc == "intrinsics") :
					tempS = "Camera" + str(cam_indx) + ".fx"
					Dest[tempS] = fs1[k][kc][0]
					tempS = "Camera" + str(cam_indx) + ".fy"
					Dest[tempS] = fs1[k][kc][1]
					tempS = "Camera" + str(cam_indx) + ".cx"
					Dest[tempS] = fs1[k][kc][2]
					tempS = "Camera" + str(cam_indx) + ".cy"
					Dest[tempS] = fs1[k][kc][3]
				elif (kc == "resolution") : 
				    tempS = "Camera.width"
				    Dest[tempS] = fs1[k][kc][0]
				    tempS = "Camera.height"
				    Dest[tempS] = fs1[k][kc][1]
				elif (kc == "T_cn_cnm1") :
				    tempS = "Stereo.T_c1_c2"
				    Dest[tempS] = fs1[k][kc]
				else :
					b = 1
				    # print("Missing handler for field: " + kc)
		else : 
			if (k == "accelerometer_noise_density") :
				tempS = "IMU.NoiseAcc"
				Dest[tempS] = v
			elif (k == "accelerometer_random_walk") :
				tempS = "IMU.AccWalk"
				Dest[tempS] = v
			elif (k == "gyroscope_noise_density") :
				tempS = "IMU.NoiseGyro"
				Dest[tempS] = v
			elif (k == "gyroscope_random_walk") :
				tempS = "IMU.GyroWalk"
				Dest[tempS] = v
			elif (k == "update_rate") :
				tempS = "IMU.Frequency"
				Dest[tempS] = v
			elif (k == "ORBextractor_nFeatures") :
				tempS = "ORBextractor.nFeatures"
				Dest[tempS] = v
			elif (k == "ORBextractor_scaleFactor") :
				tempS = "ORBextractor.scaleFactor"
				Dest[tempS] = v
			elif (k == "ORBextractor_nLevels") :
				tempS = "ORBextractor.nLevels"
				Dest[tempS] = v
			elif (k == "ORBextractor_iniThFAST") :
				tempS = "ORBextractor.iniThFAST"
				Dest[tempS] = v
			elif (k == "ORBextractor_minThFAST") :
				tempS = "ORBextractor.minThFAST"
				Dest[tempS] = v
			elif (k == "Viewer_KeyFrameSize") :
				tempS = "Viewer.KeyFrameSize"
				Dest[tempS] = v
			elif (k == "Viewer_KeyFrameLineWidth") :
				tempS = "Viewer.KeyFrameLineWidth"
				Dest[tempS] = v
			elif (k == "Viewer_GraphLineWidth") :
				tempS = "Viewer.GraphLineWidth"
				Dest[tempS] = v
			elif (k == "Viewer_PointSize") :
				tempS = "Viewer.PointSize"
				Dest[tempS] = v
			elif (k == "Viewer_CameraSize") :
				tempS = "Viewer.CameraSize"
				Dest[tempS] = v
			elif (k == "Viewer_CameraLineWidth") :
				tempS = "Viewer.CameraLineWidth"
				Dest[tempS] = v
			elif (k == "Viewer_ViewpointX") :
				tempS = "Viewer.ViewpointX"
				Dest[tempS] = v
			elif (k == "Viewer_ViewpointY") :
				tempS = "Viewer.ViewpointY"
				Dest[tempS] = v
			elif (k == "Viewer_ViewpointZ") :
				tempS = "Viewer.ViewpointZ"
				Dest[tempS] = v
			elif (k == "Viewer_ViewpointF") :
				tempS = "Viewer.ViewpointF"
				Dest[tempS] = v
			else :
				b = 1
				# print("Missing handler for field: " + k)

	return Dict

## https://gist.github.com/mstankie/58196db8e0c00a3e825909505c16e170
# A yaml constructor is for loading from a yaml node.
# This is taken from @misha 's answer: http://stackoverflow.com/a/15942429
def opencv_matrix_constructor(loader, node):
    mapping = loader.construct_mapping(node, deep=True)
    mat = np.array(mapping["data"])
    mat.resize(mapping["rows"], mapping["cols"])
    return mat


# A yaml representer is for dumping structs into a yaml node.
# So for an opencv_matrix type (to be compatible with c++'s FileStorage) we save the rows, cols, type and flattened-data
def opencv_matrix_representer(dumper, mat):
    if len(mat.shape)>1: cols=int(mat.shape[1])
    else: cols=1
    mapping = {'rows': int(mat.shape[0]), 'cols': cols, 'dt': 'd', 'data': mat.reshape(-1).tolist()}
    # mapping = {'rows': int(mat.shape[0]), 'cols': cols, 'dt': 'f', 'data': mat}
    # return dumper.represent_mapping(u"tag:yaml.org,2002:opencv-matrix", mapping)
    return dumper.represent_mapping(u"tag:yaml.org,2002:opencv-matrix", mapping,flow_style=False)
    
    
yaml.add_constructor(u"tag:yaml.org,2002:opencv-matrix", opencv_matrix_constructor)
yaml.add_representer(np.ndarray, opencv_matrix_representer)


Dest = {}
# the file that contains IMU related info
yamlFile = "imu_intrinsics.yaml"
Dest = IdentifyKeys(yamlFile, Dest)

yamlFile = "ORBex_and_Viewer.yaml"
Dest = IdentifyKeys(yamlFile, Dest)


############ WORKING ON COLOR CAMERA SPECIFIC INFO ###################################

yamlFile = "Config_COLOR_IMU.yaml"
Dest_color = IdentifyKeys(yamlFile, Dest)  

# Adding some fields specifically for RGB-D 
Dest_color["Camera.RGB"] = 1

## Get fps from metadata file if it exist
color_fps = 0
try : 
    with open('metadata_color.txt', 'r') as searchfile:
        for line in searchfile:
            if "actual_fps" in line:
                m = re.findall(r'"actual_fps":[0-9]+', line)[0]
                color_fps = int(re.search(r'[0-9]+',m)[0])
                Dest_color["Camera.fps"] = color_fps
except :
    print("No metadata_color.txt file available, not modifying Camera.fps in RGB-D yaml file")

# print(Dest_color)

# Overwriting yaml files for RGB-D, RGB-D-Inertial
file_rgbd = orbslam_path + '/Examples/RGB-D/RealSense_D435i.yaml'
new_file = "Kalibr_RGB-D.yaml"
CreateYaml(file_rgbd, Dest_color, new_file)

file_rgbd_inertial = orbslam_path + "/Examples/RGB-D-Inertial/RealSense_D435i.yaml"
new_file = "Kalibr_RGB-D-Inertial.yaml"
CreateYaml(file_rgbd_inertial, Dest_color, new_file)



############ WORKING ON INFRA CAMERA SPECIFIC INFO ###################################
yamlFile = "Config_STEREO_IMU.yaml"
Dest_stereo = IdentifyKeys(yamlFile ,Dest)


## Get fps from metadata file if it exist
infra_fps = 0
try : 
    with open('metadata_infra.txt', 'r') as searchfile:
        for line in searchfile:
            if "actual_fps" in line:
                m = re.findall(r'"actual_fps":[0-9]+', line)[0]
                infra_fps = int(re.search(r'[0-9]+',m)[0])
                Dest_color["Camera.fps"] = infra_fps
except :
    print("No metadata_color.txt file available, not modifying Camera.fps in Monocular or Stereo yaml file")

#print(Dest_stereo)

# Overwriting yaml files for Monocular, Monocular-Inertial, Stereo, Stereo-Inertial

file_mono = orbslam_path + '/Examples/Monocular/RealSense_D435i.yaml'
new_file = "Kalibr_Monocular.yaml"
CreateYaml(file_mono, Dest_stereo, new_file)

file_mono_intertial = orbslam_path + '/Examples/Monocular-Inertial/RealSense_D435i.yaml'
new_file = "Kalibr_Monocular-Inertial.yaml"
CreateYaml(file_mono_intertial, Dest_stereo, new_file)

file_stereo = orbslam_path + '/Examples/Stereo/EuRoC.yaml'                     # RealSense_D435i.yaml has info only for 1 camera
new_file = "Kalibr_Stereo.yaml"
CreateYaml(file_stereo, Dest_stereo, new_file)

file_stereo_inertial = orbslam_path + "/Examples/Stereo-Inertial/EuRoC.yaml"   # RealSense_D435i.yaml has info only for 1 camera
new_file = "Kalibr_Stereo-Inertial.yaml"
CreateYaml(file_stereo_inertial, Dest_stereo, new_file)


## due to bug with yaml.dump or some other files, https://stackoverflow.com/questions/73374036/opencv-python-api-filestorage-unable-to-get-matrix-in-right-form
## new function was created to fix the file for structures that are to be represented in matrix form
FixMatrix("Kalibr_Monocular-Inertial.yaml")
FixMatrix("Kalibr_RGB-D-Inertial.yaml")
FixMatrix("Kalibr_Stereo.yaml")
FixMatrix("Kalibr_Stereo-Inertial.yaml")

print("New Files Generated under CalibrationInfo folder! Please copy the files or rename depending on your usage. The file name and its intendend location listed below")
print("Kalibr_RGB-D.yaml              => ../ORB_SLAM3/Examples/RGB-D/ ")
print("Kalibr_RGB-D-Inertial.yaml     => ../ORB_SLAM3/Examples/RGB-D-Inertial/ ")
print("Kalibr_Monocular.yaml          => ../ORB_SLAM3/Examples/Monocular/ ")
print("Kalibr_Monocular-Inertial.yaml => ../ORB_SLAM3/Examples/Monocular-Inertial/ ")
print("Kalibr_Stereo.yaml             => ../ORB_SLAM3/Examples/Stereo/ ")
print("Kalibr_Stereo-Inertial.yaml    => ../ORB_SLAM3/Examples/Stereo-Inertial/ ")
