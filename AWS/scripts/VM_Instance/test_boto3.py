import boto3

def test_boto3():
    session = boto3.Session()
    session.resource('ec2')
    print("Połączenie z AWS EC2 nawiązane.")

test_boto3()