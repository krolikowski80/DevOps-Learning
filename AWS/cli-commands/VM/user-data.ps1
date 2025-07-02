<powershell>
# Ścieżka do pliku, który będzie informował, że User Data zostało wykonane pierwszy raz
$FirstRunFlag = "C:\FirstRunComplete.txt"

if (!(Test-Path $FirstRunFlag)) {
    # Pierwsze uruchomienie serwera - wykona się tylko raz
    Write-Output "Tworzy się nowy serwer" | Out-File -FilePath C:\startup-log.txt -Append
    New-Item -Path $FirstRunFlag -ItemType File -Force
}

# To wykona się przy każdym starcie serwera
Write-Output "Serwer startuje" | Out-File -FilePath C:\startup-log.txt -Append
</powershell>
