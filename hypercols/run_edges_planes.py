#encoding:utf-8

#
#Canny边缘检测
#

import numpy as np
import cv2

image = cv2.imread("../dataset/Planes/AC-130/AC-130_10_r0.bmp")#读入图像

image = cv2.cvtColor(image,cv2.COLOR_BGR2GRAY)#将图像转化为灰度图像
cv2.imshow("Image",image)#显示图像
print(image)
cv2.waitKey()
#Canny边缘检测
canny = cv2.Canny(image,30,150)
print(canny.shape)
cv2.imshow("Canny",canny)
cv2.waitKey()