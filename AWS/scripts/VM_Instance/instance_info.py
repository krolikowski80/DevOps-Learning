import boto3

# Utwórz klienta EC2
ec2 = boto3.client('ec2')

# Pobierz instancje o typie t2.micro
response = ec2.describe_instances(
    Filters=[
        {'Name': 'instance-type', 'Values': ['t2.micro']},
        {'Name': 'instance-state-name', 'Values': ['running', 'pending']}
    ]
)

# Wydobycie ID instancji i adresów IP
instances_info = []
for reservation in response['Reservations']:
    for instance in reservation['Instances']:
        instance_id = instance['InstanceId']
        private_ip = instance.get('PrivateIpAddress', 'Brak')
        public_ip = instance.get('PublicIpAddress', 'Brak')

        instances_info.append({
            'InstanceId': instance_id,
            'PrivateIP': private_ip,
            'PublicIP': public_ip
        })

# Wypisanie wyników
if instances_info:
    print("Znalezione instancje:")
    for inst in instances_info:
        print(f"ID: {inst['InstanceId']}, Prywatne IP: {inst['PrivateIP']}, Publiczne IP: {inst['PublicIP']}")
else:
    print("Brak uruchomionych instancji t2.micro.")