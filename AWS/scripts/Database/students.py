import mysql.connector
import os
from dotenv import load_dotenv

# Wczytanie konfiguracji z pliku .env
load_dotenv()

# Pobranie danych konfiguracyjnych z .env
DB_HOST = os.getenv("DB_ENDPOINT")
DB_USER = os.getenv("DB_USERNAME")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

# Nawiązanie połączenia z bazą MySQL
try:
    conn = mysql.connector.connect(
        host=DB_HOST,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME
    )
    cursor = conn.cursor()
    print("Połączono z bazą danych MySQL na AWS!")
except mysql.connector.Error as err:
    print(f"Błąd połączenia: {err}")
    exit()

# Funkcja tworząca tabele, jeśli nie istnieją
def create_tables():
    """
    Tworzy tabele students i grades, jeśli jeszcze nie istnieją.
    """
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS students (
            id INT AUTO_INCREMENT PRIMARY KEY,
            first_name VARCHAR(50) NOT NULL,
            last_name VARCHAR(50) NOT NULL,
            album_number VARCHAR(20) UNIQUE NOT NULL,
            created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        )
    """)
    
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS grades (
            id INT AUTO_INCREMENT PRIMARY KEY,
            album_number VARCHAR(20) NOT NULL,
            subject VARCHAR(50) NOT NULL,
            grade FLOAT NOT NULL,
            FOREIGN KEY (album_number) REFERENCES students(album_number) ON DELETE CASCADE
        )
    """)
    
    conn.commit()
    print("Tabele zostały sprawdzone i utworzone, jeśli brakowało.")

# Wywołanie funkcji tworzącej tabele
create_tables()

# Funkcja dodawania studenta do bazy danych
def add_student(first_name, last_name, album_number):
    """
    Dodaje nowego studenta do tabeli students.
    """
    query = "INSERT INTO students (first_name, last_name, album_number) VALUES (%s, %s, %s)"
    values = (first_name, last_name, album_number)
    cursor.execute(query, values)
    conn.commit()
    print(f"Dodano studenta: {first_name} {last_name}, Nr albumu: {album_number}")

# Funkcja dodawania oceny dla studenta
def add_grade(album_number, subject, grade):
    """
    Dodaje ocenę do tabeli grades dla danego studenta.
    """
    query = "INSERT INTO grades (album_number, subject, grade) VALUES (%s, %s, %s)"
    values = (album_number, subject, grade)
    cursor.execute(query, values)
    conn.commit()
    print(f"Dodano ocenę {grade} z {subject} dla studenta nr {album_number}")

# Funkcja wyświetlania listy studentów oraz ich ocen
def display_students():
    """
    Pobiera i wyświetla listę studentów oraz ich oceny.
    """
    query = "SELECT s.first_name, s.last_name, s.album_number, g.subject, g.grade FROM students s LEFT JOIN grades g ON s.album_number = g.album_number ORDER BY s.album_number"
    cursor.execute(query)
    students = cursor.fetchall()
    
    print("Lista studentów:")
    for student in students:
        print(f"{student[0]} {student[1]} | Nr albumu: {student[2]} | Przedmiot: {student[3] if student[3] else 'Brak'} | Ocena: {student[4] if student[4] else 'Brak'}")

# Główne menu programu
def main():
    """
    Interaktywne menu dla użytkownika do zarządzania studentami i ocenami.
    """
    while True:
        print("\nMenu:")
        print("1. Dodaj studenta")
        print("2. Dodaj ocenę")
        print("3. Wyświetl studentów")
        print("4. Wyjście")
        choice = input("Wybierz opcję: ")
        
        if choice == "1":
            first_name = input("Podaj imię: ")
            last_name = input("Podaj nazwisko: ")
            album_number = input("Podaj numer albumu: ")
            add_student(first_name, last_name, album_number)
        elif choice == "2":
            album_number = input("Podaj numer albumu: ")
            subject = input("Podaj przedmiot: ")
            grade = float(input("Podaj ocenę: "))
            add_grade(album_number, subject, grade)
        elif choice == "3":
            display_students()
        elif choice == "4":
            print("Zakończenie programu.")
            break
        else:
            print("Niepoprawny wybór. Spróbuj ponownie.")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    main()
