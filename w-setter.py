# -*- coding: utf-8 -*-
#############################################################

####################################################################################
import os
import re
import subprocess 
import time
import sched
import re
from time import sleep
import random
import datetime

schedule = sched.scheduler(time.time,time.sleep)

def write_register(arr):
    #start = time.time()
    p = subprocess.Popen('simple_switch_CLI --thrift-port 9090',shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True) 
    p.stdin.write('register_write threshold 0 '+str(arr[0])+'\n'+ \
                  'register_write threshold 1 '+str(arr[0]+arr[1]) +'\n'+ \
                  'register_write threshold 2 '+str(arr[1]) + '\n'+ \
                  'register_write threshold 3 '+str(arr[1]+arr[0]))
    out,err = p.communicate()

    p1 = subprocess.Popen('simple_switch_CLI --thrift-port 9091',shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True)
    p1.stdin.write('register_write threshold 0 '+str(arr[0])+'\n'+ \
                  'register_write threshold 1 '+str(arr[0]+arr[1]) +'\n'+ \
                  'register_write threshold 2 '+str(arr[1]) + '\n'+ \
                  'register_write threshold 3 '+str(arr[1]+arr[0]))

    out,err = p1.communicate()
    #end = time.time()
    #print('time:',end-start,'s')
    bb = []
    for i in range(len(arr)):
        bb.append(str(arr[i]))
    s=','.join(bb)
    print(s+" "+datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S.%f')[:-4])

    #p = subprocess.Popen('simple_switch_CLI',shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True) 
    #p.stdin.write('register_read threshold '+x)
    #print('register_read threshold '+x)
    #out_1,err_1 = p.communicate()
    #queue = re.findall('threshold\[\d\]\= \d*', out_1, re.M)
    #print ('register_read:'+str(queue[0]))  
    #end = time.time()
    #print('time:', end, 's')

def run():
    for i in range(500):
        b = random.sample(range(0,10),2)
        write_register(b)
        time.sleep(5)

if __name__ == "__main__":
    run()


