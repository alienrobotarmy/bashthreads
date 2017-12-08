#!/bin/bash
#
# Bash multi-threading library
# 
# Copyright (c) 2014 Jess Mahan
# 
# This library has 3 main functions:
# thread_init <max threads>
# thread_create <command> <args>
# thread_wait (final)
#
# thread_init <max_threads>
#   This function MUST be called ONLY ONCE, and BEFORE any other thread calls
#   
# thread_create <command> <args>
#   Spawn <max threads> of <command> <args>
#   You should call thread_wait immediately after this.
# 
# thread_wait
#   Block until we are no longer at <max threads>
#   When called with an argument, blocks parent until all threads are complete
#
# Usage example:
# (This will create 64 threads of function nslkup)
#
# function nslkup {
#     dig +short $1
# }
# thread_init 64
# for i in $(cat hosts.txt)
# do
#    thread_create nslkup ${i}
#    if [ $? -eq 1 ]; then
#        thread_wait
#        thread_create nslkup ${i}
#    fi
# done
# thread_wait final
#
function thread_init {
  local i=0
  J_THREADS_MAX_THREADS=$1
  J_THREADS_ID=$(date +%s)$((RANDOM%1000))
  J_THREADS_THREAD_ID=0
  export J_THREADS_MAP
  while [ ${i} -lt ${J_THREADS_MAX_THREADS} ]
  do
      J_THREADS_MAP[${i}]=0
      let $((i++))
  done
}
function thread_cleanup {
    rm -f /tmp/j-threads-${J_THREADS_ID}*.lck
}
function thread_count {
    local i=0
    local x=0

    for i in $(ls -1 /tmp/j-threads-${J_THREADS_ID}-*.lck 2>/dev/null)
    do
	let $((x++))
    done
    return ${x}
}
function thread_wait {
  local count=0
  local waitfor=${J_THREADS_MAX_THREADS}

  if [ $1 ]; then waitfor=1; fi

  thread_count; count=$?
  while [ ${count} -ge ${waitfor} ]
  do
    thread_count; count=$?
    sleep 0.05
  done
}
function thread_run {
    touch /tmp/j-threads-${J_THREADS_ID}-${J_THREADS_THREAD_ID}.lck
    $*
    rm -f /tmp/j-threads-${J_THREADS_ID}-${J_THREADS_THREAD_ID}.lck
}
function thread_create {
    local buf=""
    local ret=0
    local count=0

    thread_count; count=$?
    if [ ${count} -lt ${J_THREADS_MAX_THREADS} ]; then
        let $((J_THREADS_THREAD_ID++))
	thread_run $* & 
	return 0
    else
	return 1
    fi
}
