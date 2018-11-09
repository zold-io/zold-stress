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

first=$(start_node)
trap "halt_nodes ${first}" EXIT

zold --public-key=id_rsa.pub create 0000000000000000
zold --public-key=id_rsa.pub create abcdabcdabcdabcd
zold pay --private-key=id_rsa 0000000000000000 NOPREFIX@abcdabcdabcdabcd 4.95 'To test'

zold-stress --help
