#!/bin/bash

function start_node {
  port=$(reserve_port)
  mkdir ${port}
  cd ${port}
  zold node --trace --invoice=MULTINODE@ffffffffffffffff \
    --host=localhost --port=${port} --bind-port=${port} --dump-errors \
    --no-metronome --halt-code=test --threads=1 --strength=2 > log.txt &
  pid=$!
  echo ${pid} > pid
  cd ..
  wait_for_url http://localhost:${port}/
  echo ${port}
}

nodes=($(start_node) $(start_node) $(start_node) $(start_node))
trap "halt_nodes ${nodes[*]}" EXIT
for port in ${nodes[@]}; do
  cd ${port}
  zold remote clean
  for friend in ${nodes[@]}; do
    if [ "${port}" != "${friend}" ]; then
      zold remote add localhost ${friend}
    fi
  done
  cd ..
done

zold remote clean
for port in ${nodes[@]}; do
  zold remote add localhost ${port}
done

zold --public-key=id_rsa.pub create 0000000000000000
zold --public-key=id_rsa.pub create abcdabcdabcdabcd
zold pay --private-key=id_rsa 0000000000000000 abcdabcdabcdabcd 4.95 'To test'
zold push 0000000000000000 --ignore-score-weakness
zold remove 0000000000000000

zold-stress --rounds=8 --wait=10 --threads=${#nodes[@]} --pool=8 --batch=8 --private-key=id_rsa --ignore-score-weakness

zold show
