#!/bin/sh
set -e

CLUSTER="cluster-services-70768bd"
TASK_FAMILY="task-family-paperclip"
SG="sg-03abcce32544becdb"
SUBNETS="subnet-0f163112d91f86daa,subnet-0ccd8400cecf0363a"
REGION="eu-west-1"
BASE_URL="https://paperclip.ailtir.ai"
LOG_GROUP="/ecs/task-family-paperclip"

TASK_DEF=$(aws ecs list-task-definitions \
  --family-prefix "$TASK_FAMILY" \
  --region "$REGION" \
  --sort DESC \
  --query 'taskDefinitionArns[0]' \
  --output text)

echo "Running bootstrap task using $TASK_DEF ..."

OVERRIDES=$(cat << 'EOF'
{
  "containerOverrides": [{
    "name": "paperclip",
    "command": [
      "/bin/sh", "-c",
      "python3 -c \"import json,os,datetime; cfg={'\\$meta':{'version':1,'updatedAt':datetime.datetime.now(datetime.timezone.utc).isoformat(),'source':'onboard'},'server':{'deploymentMode':'authenticated','exposure':'public','host':'0.0.0.0','port':3100},'auth':{'baseUrlMode':'explicit','publicBaseUrl':os.environ['PAPERCLIP_PUBLIC_URL']},'database':{'mode':'postgres','connectionString':os.environ['DATABASE_URL']},'logging':{'mode':'file','logDir':'/tmp/logs'},'storage':{'provider':'local_disk'},'secrets':{'provider':'local_encrypted'}}; json.dump(cfg,open('/tmp/config.json','w'))\" && /app/cli/node_modules/.bin/tsx /app/cli/src/index.ts auth bootstrap-ceo --config /tmp/config.json --base-url $PAPERCLIP_PUBLIC_URL"
    ]
  }]
}
EOF
)

TASK_ARN=$(aws ecs run-task \
  --cluster "$CLUSTER" \
  --task-definition "$TASK_DEF" \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SG],assignPublicIp=DISABLED}" \
  --overrides "$OVERRIDES" \
  --region "$REGION" \
  --query 'tasks[0].taskArn' \
  --output text)

TASK_ID=${TASK_ARN##*/}
echo "Task started: $TASK_ID"
echo "Waiting for task to complete..."

aws ecs wait tasks-stopped \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ID" \
  --region "$REGION"

EXIT_CODE=$(aws ecs describe-tasks \
  --cluster "$CLUSTER" \
  --tasks "$TASK_ID" \
  --region "$REGION" \
  --query 'tasks[0].containers[0].exitCode' \
  --output text)

LOG_STREAM="paperclip/paperclip/$TASK_ID"
echo ""
echo "=== Task output ==="
aws logs get-log-events \
  --log-group-name "$LOG_GROUP" \
  --log-stream-name "$LOG_STREAM" \
  --region "$REGION" \
  --start-from-head \
  --query 'events[*].message' \
  --output text 2>/dev/null || echo "(no logs)"

if [ "$EXIT_CODE" = "0" ]; then
  echo ""
  echo "Bootstrap complete. Visit the invite URL above to claim the instance."
else
  echo ""
  echo "Bootstrap failed (exit code $EXIT_CODE)."
  exit 1
fi
