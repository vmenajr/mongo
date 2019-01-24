A look at one of the CTF problems I solved to win the contest

The source for the target was supplied and we were told we needed to force the target to output the flag.

The full source is [jumpy.cpp](jumpy.cpp). It would appear that getting the flag out required setting `step1 = step2 = step3 = true` to force the flag to be printed.

Interestingly, the authors decided to print the address of the stone functions which could be used to toggle the state of the step flags.

I noticed the stone function pointers looked like 32 bit addresses in the remote output so I built the source on my local using 32 bit.

I then noticed the remote addresses looked identical to the printed value from my local version.  My lazyness kicked into high gear as I looked at my options:
1. Craft 3 stack frames to force the flags to true by overflowing [smasher](jumpy.cpp#L42) on line 42
1. Craft a single stack frame which sends me to line 54 and I'm done! Of course this would only work if the remote text segment is always the same but it was worth a shot.

I wasn't given the address for line 54 however given the stone function addresses looked the same as my local build I dumped out the disassembly from my local and used it's address.

Time to test drive my theory.

I've included a [Vagrantfile](Vagrantfile) which stands up a VM with all the required software to make this happen.  I also added the research steps I used in coming up with the solution.

You'll notice in the Vagrantfile that it also runs the exploit after it ensures ASLR is fully enabled.

Take it for a spin with `vagrant up test`

### ToDo
* Describe the next step I took by using ROP to simply print the flag directly
* Explore the steps I took to arrive at `get_shell.py`



