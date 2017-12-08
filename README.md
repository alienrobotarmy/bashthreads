#  Bash multi-threading library
Copyright (c) 2014 Jess Mahan

This simple to use library provides multi-threading capability for your bash scripts in a posix threads style.

## Getting Started

Include this into your script:
```
#!/bin/bash
source ~/threads.sh
```

## Library Functions
### thread_init <max threads>
  Initialize the library, limiting the maximum thread count to <max threads>
  Defining max threads is important, otherwise you could potentially fork bomb yourself.
  
  #### This function MUST be called ONLY ONCE, and BEFORE any other thread calls
  
  <max threads> Create no more than this many threads
  
### thread_create <command> <args>
  Create a single thread of <command> with <args>
  
  thread_wait should be called immediately after this.
  
  <command> A command to run in a new thread / process
  <args> Arguments to pass to the command
  
### thread_wait (final)
  Block until we are no longer at <max threads>
  
  When called with an argument (such as "thread_wait final"), blocks parent until all threads are complete
    

## Example:
In this example, we have a file called "hosts.txt" which contains a single hostname per line.
We then create 64 simulaneous worker threads to each resolve the hostname and then exit. 

```
#!/bin/bash

. ./threads.sh

function nslkup {
     dig +short $1
}
thread_init 64
for i in $(cat hosts.txt)
do
  thread_create nslkup ${i}
  if [ $? -eq 1 ]; then
    thread_wait
    thread_create nslkup ${i}
  fi
done
thread_wait final
```
