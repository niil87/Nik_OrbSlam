# Nik_OrbSlam

Welcome to this repository. This repository was created as an effort to support Research effort at Lund University. There are two bash script provided along with some support files to help with speeding up ORB-SLAM3 research efforts without need to worry about missing packages

The original files picked up from https://github.com/UZ-SLAMLab/ORB_SLAM3 and we thank the contributors for the original files. This repository contains fixes necessary for the packages to work on Ubuntu 20.04 as the original repository are either missing some files or some fixes.

The bash script "runMe.sh" installs all the packages in one go. Please note that this is a simple bash script and does not handle runtime error correction. It can only detect errors and will stop at point when an error is detected. By error I mean, program fails to run or installation failed, etc.

The second bash script "kalibrProc.sh" is to help with extraction of calibration related information required for generating the yaml files. 


## Requirement: 
Install Git on your station. Reference Link @ https://github.com/git-guides/install-git

## Steps to install ORB-SLAM3
Clone the files from Github
```
git clone https://github.com/niil87/Nik_OrbSlam.git
```

Go into the main directory and make a bash file an executable
```
cd Nik_OrbSlam/
chmod +x runMe.sh 
```

Run the file 
```
./runme.sh
```
