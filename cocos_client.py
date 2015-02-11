import os
import sys
from socket import *
from threading import Thread

CMD_PORT = 6010
BUFFER = 1024

cmdSocket = None

def receiver():
    while True:
        res = cmdSocket.recv(BUFFER)
        if len(res) == 0: break
        print(res)

if __name__ == "__main__":
    cmdSocket = socket(AF_INET, SOCK_STREAM)
    cmdSocket.connect((sys.argv[1], CMD_PORT))
    Thread(target = receiver).start()
    try:
        while True:
            cmdSocket.send(raw_input() + '\n')
    except:
        pass
    cmdSocket.send('exit\n')
    cmdSocket.close()
