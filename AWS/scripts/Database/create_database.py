import boto3
import time
import os
from dotenv import load_dotenv, set_key
from dotenv import dotenv_values

# Wczytanie konfiguracji z pliku .env
load_dotenv()


def update_env_variable(key, value):
    """
    Aktualizuje wartość zmiennej w pliku .env.
    """
    env_path = ".env"
    set_key(env_path, key, value)


# Pobranie danych konfiguracyjnych z .env
AWS_REGION = os.getenv("AWS_REGION")
DB_INSTANCE_IDENTIFIER = os.getenv("DB_INSTANCE_IDENTIFIER")
DB_NAME = os.getenv("DB_NAME")
DB_USERNAME = os.getenv("DB_USERNAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_INSTANCE_CLASS = os.getenv("DB_INSTANCE_CLASS")
DB_STORAGE = int(os.getenv("DB_STORAGE"))
DB_ENGINE = os.getenv("DB_ENGINE")
DB_VERSION = os.getenv("DB_VERSION")

# Inicjalizacja klienta AWS RDS
rds_client = boto3.client("rds", region_name=AWS_REGION)


def create_rds_instance():
    """
    Tworzy instancję MySQL w AWS RDS i zapisuje jej endpoint do pliku .env.
    """
    try:
        response = rds_client.create_db_instance(
            DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER,
            AllocatedStorage=DB_STORAGE,
            DBName=DB_NAME,
            Engine=DB_ENGINE,
            EngineVersion=DB_VERSION,
            DBInstanceClass=DB_INSTANCE_CLASS,
            MasterUsername=DB_USERNAME,
            MasterUserPassword=DB_PASSWORD,
            PubliclyAccessible=True,
            BackupRetentionPeriod=7,
            MultiAZ=False,
            StorageType="gp2",
        )
        print(f"Tworzenie instancji RDS '{DB_INSTANCE_IDENTIFIER}'...")
    except Exception as e:
        print(f"Błąd: {e}")


def wait_for_db():
    """
    Czeka, aż baza danych będzie dostępna, a następnie zapisuje jej endpoint do .env.
    """
    print("Oczekiwanie na gotowość instancji RDS...")
    while True:
        response = rds_client.describe_db_instances(
            DBInstanceIdentifier=DB_INSTANCE_IDENTIFIER)
        db_instance = response["DBInstances"][0]
        status = db_instance["DBInstanceStatus"]
        print(f"Status RDS: {status}")

        if status == "available":
            endpoint = db_instance["Endpoint"]["Address"]
            print(f"Baza MySQL dostępna pod adresem: {endpoint}")
            update_env_variable("DB_ENDPOINT", endpoint)
            break

        time.sleep(30)


if __name__ == "__main__":
    create_rds_instance()
    wait_for_db()
