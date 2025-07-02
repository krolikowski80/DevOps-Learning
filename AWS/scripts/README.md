# Konfiguracja `pyenv` i `virtualenv` na Mac do pracy z AWS
## [Korzystam z tutoriali - Realpython](https://realpython.com/intro-to-pyenv/)

## Wprowadzenie

Zacznę od wyizolowania środowiska, aby uniknąć konfliktów z systemowym Pythonem. W tym celu użyję `pyenv` oraz `virtualenv`.

---

## Krok 1: Instalacja `pyenv`

1. Instaluję `pyenv` i wymagane zależności:
   ```bash
   brew update && brew upgrade
   brew install pyenv
   ```

2. Dodaję do `.zshrc`:
   ```bash
   export PATH="$HOME/.pyenv/bin:$PATH"
   eval "$(pyenv init --path)"
   eval "$(pyenv virtualenv-init -)"
   ```

3. Przeładuję konfigurację:
   ```bash
   source ~/.zshrc
   ```

4. Sprawdzę instalację:
   ```bash
   pyenv --version
   ```

5. Sprawdzam dostępne wersje Pythona w pyenv dla serii `3.12 i 3.13` 
    ```bash
    pyenv install --list | grep  "3\\.12|3\\.13"
    ```
---

## Krok 2: Instalacja Pythona i `virtualenv`

1. Zainstaluję sprawdzoną wersję `Python 3.12.8`:
   ```bash
   pyenv install 3.12.8
   ```

2. Utwórzę środowisko wirtualne:
   ```bash
   pyenv virtualenv 3.12.8 aws-env
   ```

3. Aktywuję środowisko:

   **Uwaga:** Zrób to w katalogu, w którym trzymasz plikki python

   ```bash
   pyenv activate aws-env
   ```

 - I ustawię je jako domyślne:
   ```bash
   pyenv local aws-env
   ```
---

## Podsumowanie

Środowisko Python jest teraz odizolowane i gotowe do pracy z AWS! 🚀

