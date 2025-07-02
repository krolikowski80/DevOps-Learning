import boto3
import os

# Nazwa nowego klucza SSH
KEY_NAME = "aws-key"

# Tworzenie klienta EC2
ec2_client = boto3.client("ec2")

# Tworzenie pary kluczy
response = ec2_client.create_key_pair(KeyName=KEY_NAME)

# Pobranie klucza prywatnego
private_key = response["KeyMaterial"]

# Zapisanie klucza do pliku
key_file = f"{KEY_NAME}.pem"
with open(key_file, "w") as file:
    file.write(private_key)

# Ustawienie odpowiednich uprawnień dla pliku klucza (tylko właściciel może czytać)
os.chmod(key_file, 0o400)

print(f"Klucz SSH '{KEY_NAME}' został utworzony i zapisany w pliku: {key_file}")