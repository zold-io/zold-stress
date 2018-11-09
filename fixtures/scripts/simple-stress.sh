#!/bin/bash

function start_node {
  port=$(reserve_port)
  mkdir ${port}
  cd ${port}
  zold node --trace --invoice=SPREADWALLETS@ffffffffffffffff \
    --host=localhost --port=${port} --bind-port=${port} --dump-errors \
    --standalone --no-metronome --halt-code=test \
    --threads=0 > log.txt &
  pid=$!
  echo ${pid} > pid
  cd ..
  wait_for_url http://localhost:${port}/
  echo ${port}
}

port=$(start_node)
trap "halt_nodes ${port}" EXIT
zold remote clean
zold remote add localhost ${port}

zold --public-key=id_rsa.pub create 0000000000000000
zold --public-key=id_rsa.pub create abcdabcdabcdabcd
zold pay --private-key=id_rsa 0000000000000000 abcdabcdabcdabcd 4.95 'To test'
zold push 0000000000000000
zold remove 0000000000000000

# zold-stress --rounds=1000 --wait=5 --threads=12 --pool=8 --batch=32 --private-key=id_rsa
zold-stress --rounds=4 --wait=5 --threads=4 --pool=4 --batch=4 --private-key=id_rsa
