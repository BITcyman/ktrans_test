#!/bin/bash

set -e

DEFAULT_NUMA_FLAG=False

NUMA_FLAG=${1:-$DEFAULT_NUMA_FLAG}

echo "ktrans test start!"


# ktrans 启动测试，测试是否能够正常运行
echo "ktrans start test start!"
cd start || exit 1  
bash start_test.sh $NUMA_FLAG
cd ..

# ktrans api 测试，测试 ktrans 相关 api 的正确性和稳定性
cd api || exit 1  
bash test_api.sh $NUMA_FLAG
cd ..

# ktrans speed 测试，测试该版本 ktrans 的性能是否有跌损
cd speed || exit 1 
bash test_speed.sh $NUMA_FLAG
cd ..


# ktrans correct 测试，测试该版本 ktrans 的智商是否有跌损
cd correct || exit 1 
bash test_correct.sh $NUMA_FLAG
cd ..


echo "ktrans test finish!"