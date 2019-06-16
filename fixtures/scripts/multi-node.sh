#!/bin/bash

# rm -rf /code/temp/stress/*
# cp id_rsa* /code/temp/stress
# cd /code/temp/stress

function start_node {
  port=$1
  mkdir ${port}
  cd ${port}
  zold remote clean
  zold node --trace --invoice=MULTINODE@ffffffffffffffff \
    --host=localhost --port=${port} --bind-port=${port} --dump-errors \
    --no-metronome --halt-code=test --threads=1 --strength=3 --pretty=full > log.txt 2>&1 &
  pid=$!
  echo ${pid} > pid
  cd ..
  wait_for_url "http://localhost:${port}/"
}

nodes=()
for i in `seq 1 4`; do
  port=$(reserve_port)
  nodes+=($port)
  start_node $port &
done
wait

trap "halt_nodes ${nodes[*]}" EXIT

for port in ${nodes[@]}; do
  {
    cd ${port}
    for friend in ${nodes[@]}; do
      if [ "${port}" != "${friend}" ]; then
        zold remote add localhost ${friend} --skip-ping
      fi
    done
    cd ..
  } &
done
wait

zold remote clean
for port in ${nodes[@]}; do
  zold remote add localhost ${port} --skip-ping &
done
wait

zold --public-key=id_rsa.pub create 0000000000000000
zold --public-key=id_rsa.pub create abcdabcdabcdabcd
zold pay --private-key=id_rsa 0000000000000000 abcdabcdabcdabcd 4.95 'To test'
zold push 0000000000000000 --ignore-score-weakness --tolerate-edges
zold remove 0000000000000000

# sleep 10000

zold-stress --rounds=4 --wait=10 --threads=${#nodes[@]} --pool=8 --batch=8 \
  --private-key=id_rsa --ignore-score-weakness --skip-update
