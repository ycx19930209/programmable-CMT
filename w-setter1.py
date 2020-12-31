# -*- coding: utf-8 -*-
import os
import re
import subprocess 
import time
import sched
import re
from time import sleep
import random

schedule = sched.scheduler(time.time,time.sleep) #用于定时

def write_register(x,circle,port):
    #start = time.time()
    p = subprocess.Popen('simple_switch_CLI --thrift-port '+port,shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True) 
    p.stdin.write('register_write threshold '+x+' '+circle)
    #print('register_write threshold '+x+' '+circle)
    out,err = p.communicate()
    
    #p = subprocess.Popen('simple_switch_CLI',shell=True,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,universal_newlines=True) 
    #p.stdin.write('register_read threshold '+x)
    #print('register_read threshold '+x)
    #out_1,err_1 = p.communicate()
    #queue = re.findall('threshold\[\d\]\= \d*', out_1, re.M)
    #print ('register_read:'+str(queue[0]))  #读取register验证
    #end = time.time()
    #print('time:', end, 's')

def run():
    start = time.time()
    b = random.sample(range(0,10),3)
    print(b)
    # write_register(a, str(b[0]))
    
    print(time.strftime("%H:%M:%S",time.localtime()))
    #stdin.write('register_write threshold 0 1')
if __name__ == "__main__":
    run()


