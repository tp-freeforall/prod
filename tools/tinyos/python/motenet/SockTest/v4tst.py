#Echo client program
import socket

HOST = '192.168.1.132'
PORT = 50007
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
print('s is:', s)
s.connect((HOST, PORT))
print('s.connect is:', s.connect)
out_chars = 'Hey Carl'
while(len(out_chars) > 0):
    still_send = s.send(out_chars)
    out_chars = out_chars[still_send:]

#If you can use a blocking socket, use sendall()
#When using _DGRAM use socket.sendto(data,address)

data = s.recv(1024)
print('data is:', data)
s.close()
print 'Received ', repr(data)
