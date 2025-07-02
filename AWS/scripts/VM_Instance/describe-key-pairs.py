import boto3

ec2_client = boto3.client("ec2")

response = ec2_client.describe_key_pairs()
key_names = [key["KeyName"] for key in response["KeyPairs"]]

print("Dostępne klucze SSH:", key_names)