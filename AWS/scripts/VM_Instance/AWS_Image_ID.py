import boto3

ec2_client = boto3.client('ec2') #interesują mnie EC2
images = ec2_client.describe_images(Owners=['amazon']) #Pobiera obrazy z AWS

for image in images['Images'][:15]:  # Pobiera tylko 15 pierwszych wyników
    print(f"AMI ID: {image['ImageId']}, Name: {image['Name']}")


# Coś tu ku...wa nie działa jak chcę, nie wiem co jest nie tak, ale nie działa
# więc wziąłem instance ID z AWS Console i wpisałem ręcznie
# AWS Extansions pack do VSC jest zajefajny ;)
# Pisze połowe mojego kodu za mnie  :D
