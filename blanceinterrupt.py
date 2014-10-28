#!/usr/bin/python

import os
import re
import sys
import math
import subprocess



COLOR_CHOICE = { 
'ERROR':'\033[31m',
'INFO':'\033[32m',
'WARNING':'\033[33m',
'CRITICAL':'\033[35m',
'DEBUG':'\033[37m',
'NOTSET':'\033[0m',
}



affinity_vec_igb = []
ETH = []
#affinity_vec_tg3 = ['3', 'C', '30', 'C0', '300', 'C00', '3000', 'C000']

def findIrqNu():
    cmd = "grep eth /proc/interrupts|awk '{print $1,$2}'"
    p = subprocess.Popen(cmd,shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT ) 
    #error = p.stderr.read()                                                                             
    retval = p.wait()                                                                                   
    text = p.stdout.read().rstrip()
    if p.returncode == 0:
        for i  in text.split("\n"):
            ETH.append(i.rstrip(":"))
            info = ETH
    else :
        info = ip + "Find info ERROR"
        print COLOR_CHOICE['ERROR']+info+COLOR_CHOICE['NOTSET']
        os.system(exit(1))
    return info

def findCpuNu():
    cmd = "cat /proc/cpuinfo |grep processor |wc -l"
    p = subprocess.Popen(cmd,shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT ) 
    #error = p.stderr.read()                                                                             
    retval = p.wait()                                                                                   
    text = p.stdout.read().rstrip()
    if p.returncode == 0:
        for i in range(int(text)):
            nu_10 = math.pow(2,i)
            nu_16 = hex(int(nu_10))
            affinity_vec_igb.append(nu_16)
            info = affinity_vec_igb       
    else :
        info = ip + "Find info ERROR"
        print COLOR_CHOICE[ERROR]+info+COLOR_CHOICE[NOTSET]
        os.system(exit(1))
    return info


if __name__ == "__main__":
    a = findCpuNu()
    b = findIrqNu()
    print a,b 
