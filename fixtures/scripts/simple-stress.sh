#!/bin/bash

function start_node {
  port=$1
  mkdir ${port}
  cd ${port}
  zold node --trace --invoice=SPREADWALLETS@ffffffffffffffff \
    --host=localhost --port=${port} --bind-port=${port} --dump-errors \
    --standalone --no-metronome --halt-code=test \
    --threads=0 > log.txt 2>&1 &
  pid=$!
  echo ${pid} > pid
  cd ..
  wait_for_url http://localhost:${port}/
}

port=$(reserve_port)
$(start_node $port)
trap "halt_nodes ${port}" EXIT
zold remote clean
zold remote add localhost ${port}

zold --public-key=id_rsa.pub create 0000000000000000
zold --public-key=id_rsa.pub create abcdabcdabcdabcd
zold pay --private-key=id_rsa 0000000000000000 abcdabcdabcdabcd 4.95 'To test'
zold push 0000000000000000
zold remove 0000000000000000

zold-stress --rounds=4 --wait=5 --threads=16 --pool=16 --batch=8 --private-key=id_rsa --verbose
# zold-stress --rounds=4 --wait=5 --threads=4 --pool=4 --batch=4 --private-key=id_rsa
