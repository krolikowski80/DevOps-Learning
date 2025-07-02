import boto3

ec2 = boto3.client('ec2')

response= ec2.run_instances(
    ImageId='ami-099da3ad959447ffa',
    InstanceType='t2.micro',
    MinCount=1,
    MaxCount=1,
    KeyName='aws-key'
)

instance_id = response['Instances'][0]['InstanceId']
print(f"Instance ID: {instance_id}")
