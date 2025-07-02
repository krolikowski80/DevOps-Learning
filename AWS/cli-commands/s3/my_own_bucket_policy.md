# Polityka bucketu S3 z NotPrincipal

Poniżej znajduje się przykładowa polityka (resource-based policy) dla prywatnego bucketu S3:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllExceptUserAndRoot",
      "Effect": "Deny",
      "NotPrincipal": {
        "AWS": [
          "arn:aws:iam::173504366721:user/t.krolikowski",
          "arn:aws:iam::173504366721:root"
        ]
      },
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::tkrolikowski-bucket01",
        "arn:aws:s3:::tkrolikowski-bucket01/*"
      ]
    }
  ]
}
```

---

## Wyjaśnienie kluczowych elementów

1. **`Version`: "2012-10-17"**  
   To standardowy tag wersji polityki AWS. Nie jest to data wdrożenia w Twoim projekcie – określa po prostu specyfikację formatu polityk.

2. **`Sid`: "DenyAllExceptUserAndRoot"**  
   Opisowy identyfikator klauzuli w polityce.

3. **`Effect`: "Deny"**  
   Oznacza, że ta klauzula będzie *blokować* dostęp do zasobów.

4. **`NotPrincipal`**  
   - Kluczowe pole różniące się od standardowego `Principal`.  
   - `NotPrincipal` pozwala wskazać *kogo dany `Effect` (Deny) nie dotyczy*.  
   - W tym wypadku mówimy: *"Zablokuj wszystkich **poza** użytkownikiem `t.krolikowski` i rootem konta 173504366721"*.

5. **`Action`: "s3:*"**  
   Zablokowane (dla wszystkich spoza `NotPrincipal`) będą wszystkie akcje `s3`, np. `s3:GetObject`, `s3:ListBucket`, `s3:PutObject`, `s3:DeleteObject`, itp.

6. **`Resource`**  
   - Tablica zasobów:  
     - `"arn:aws:s3:::tkrolikowski-bucket01"` – sam bucket.  
     - `"arn:aws:s3:::tkrolikowski-bucket01/*"` – każdy obiekt w tym buckecie.  
   - Oznacza, że polityka odnosi się do wszystkich operacji na bucket i jego zawartości.

---

## Jak to działa?

- Każdy, kto **nie** jest w `NotPrincipal` → czyli każda rola, użytkownik IAM (w tym z innych kont), anonimowy dostęp, itp. – jest **blokowany**.
- Jednocześnie, użytkownik `arn:aws:iam::173504366721:user/t.krolikowski` oraz `arn:aws:iam::173504366721:root` *nie* podlegają temu Deny (a więc *mogą* wykonywać akcje S3, o ile polityka IAM lub rola im na to zezwala).
- `root` to unikalna fraza w stylu `arn:aws:iam::KONTO_AWS:root`. Zazwyczaj, jeśli chcesz dopuścić konto root do wszystkiego, dodajesz ten ARN do listy wyjątków.

### Zasada priorytetu w politykach AWS

Warto pamiętać:
- **Explicit Deny** (czyli `Effect: Deny`) zawsze ma wyższy priorytet niż Allow.
- Jeśli w innej klauzuli mamy `Effect: Allow` dla danego podmiotu, ale tu obowiązuje `Deny`, to i tak *Deny wygrywa*.
- Stąd właśnie `NotPrincipal` – pozwala wykluczyć konkretnych principalów, których nie chcemy zablokować.

---

## Kroki wdrożenia

1. **Zaloguj się** jako root (lub inny podmiot, który może modyfikować polityki resource-based, jeśli poprzedni Deny tego nie blokuje).  
2. **Pobierz i zmodyfikuj politykę** bucketa – możesz to zrobić w konsoli AWS (S3 → Permissions → Bucket policy) albo przez CLI:
   ```bash
   aws s3api get-bucket-policy \
       --bucket tkrolikowski-bucket01
   ```
3. **Zastąp** dotychczasowy fragment polityki lub wklej powyższą politykę w całości (pamiętaj, żeby wstawić właściwą nazwę bucketa i poprawne ARNy).

   - znajdź swój ARN
   ```bash
   aws iam get-user --user-name t.krolikowski
   ```

4. **Wgraj** zaktualizowany plik (jeśli używasz CLI):  
   ```bash
   aws s3api put-bucket-policy \
       --bucket tkrolikowski-bucket01 \
       --policy file://twoja_nowa_polityka.json
   ```
5. **Sprawdź** dostęp dla `t.krolikowski` i ewentualnie użytkowników z innego konta – powinni otrzymać błąd AccessDenied.

---

## Podsumowanie

Dzięki zastosowaniu `NotPrincipal` i jednej klauzuli Deny, możesz łatwo:
- **Odciąć** od bucketa wszystkich poza wybranym użytkownikiem IAM i rootem.
- Zachować zgodność z regułą, że explicit Deny ma najwyższy priorytet.

W efekcie, bucket jest zamknięty dla całego świata, a dostęp do niego ma tylko Twój użytkownik i ewentualnie root konta AWS.

