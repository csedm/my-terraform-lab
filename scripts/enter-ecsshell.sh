#!/usr/bin/env bash

cluster='ecs-cluster'
env='dev'
cluster_name=$cluster-$env
service_name='ecs-mgt'
container_name='mgt'
shell='/bin/ash'

current_state=`aws ecs describe-services --cluster $cluster_name --service $service_name | jq '.services[].desiredCount'`

if [ $current_state == 0 ]; then
    aws ecs update-service --cluster $cluster_name --service $service_name --desiredcount 1
    echo "Waiting 30 seconds for the container to launch..."
    sleep 30

fi

task_id=`aws ecs list-tasks --cluster $cluster_name --service $service_name | jq -r '.taskArns[0] | split("/")[-1]'`

echo "Connecting to task $task_id..."

aws ecs execute-command --cluster $cluster_name --task $task_id --container $container_name --interactive --command $shell
