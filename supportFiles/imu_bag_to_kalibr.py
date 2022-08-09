import numpy as np
import re
import os


def CreateFile(*files) :

	indx = np.size(files)
	stamp = np.empty([1, 1], dtype="S20")
	info = np.zeros((1, 3))

	i = 0

	# Extracting only time stamp
	f1 = files[0]
	# getting rid of first line
	f1.readline()
	for line in f1 :
		currentline = re.split('\n|,',line)
		stamp[i] = currentline[1]
		stamp = np.pad(stamp, ((0, 1), (0, 0)), mode='constant', constant_values=0)
		i = i + 1

	# Extracting the information
	f2 = files[1]
	if (indx == 3):
		f3 = files[2]
		# getting rid of first line
		f2.readline()
		i = 0
		for line in f2 :
			currentline = re.split('\n|,',line)
			for j in range(0, 3):
				info[i][j] = currentline[j+1]
				info = np.pad(info, ((0, 1), (0, 0)), mode='constant', constant_values=0)
			i = i + 1

	for k in range(0,i) :
		newline = str(stamp[k])[3:-2]
		newline = newline[:-9] + '.' + newline[-9:]
		if (indx == 3):
			newline = newline + "," + str(info[k][0]) + "," + str(info[k][1]) + "," + str(info[k][2]) + '\n'
			f3.write(newline)
		else :
			newline = newline + '\n'
			f2.write(newline)


file1 = open('IMU_Data/IMU/acc_stamp.txt','r')
file2 = open('IMU_Data/IMU/acc_info.txt','r')
file3 = open('IMU_Data/IMU/acc.txt','w')
  
CreateFile(file1,file2,file3) 

file1.close()
file2.close()
file3.close()

file1 = open('IMU_Data/IMU/gyro_stamp.txt','r')
file2 = open('IMU_Data/IMU/gyro_info.txt','r')
file3 = open('IMU_Data/IMU/gyro.txt','w')
  
CreateFile(file1,file2,file3) 

file1.close()
file2.close()
file3.close()

file1 = open('IMU_Data/cam0/times_stamp.txt','r')
file2 = open('IMU_Data/cam0/times.txt','w')
  
CreateFile(file1,file2) 

file1.close()
file2.close()



os.system("rm -rf IMU_Data/IMU/acc_stamp.txt")
os.system("rm -rf IMU_Data/IMU/acc_info.txt")
os.system("rm -rf IMU_Data/IMU/gyro_stamp.txt")
os.system("rm -rf IMU_Data/IMU/gyro_info.txt")
os.system("rm -rf IMU_Data/cam0/times_stamp.txt")
