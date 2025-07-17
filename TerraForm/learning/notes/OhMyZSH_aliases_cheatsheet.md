# DevOps Aliases Cheat Sheet - Oh My Zsh 🚀

## 🔍 **Sprawdzanie aliasów w systemie**

### **Zobacz wszystkie aliasy:**
```bash
alias | grep -E "(terraform|docker|kubectl|git|aws)"
```

### **Aliasy per plugin:**
```bash
# Terraform aliases
alias | grep tf

# Docker aliases  
alias | grep docker

# Kubectl aliases
alias | grep kubectl

# Git aliases
alias | grep git
```

### **Sprawdź które pluginy masz aktywne:**
```bash
echo $plugins
# lub
cat ~/.zshrc | grep "plugins="
```

---

## 🔧 **Terraform Aliases (terraform plugin)**

| Alias | Polecenie | Opis |
|-------|-----------|------|
| `tf` | `terraform` | Główne polecenie |
| `tfi` | `terraform init` | Inicjalizacja |
| `tfa` | `terraform apply` | Zastosuj zmiany |
| `tfaa` | `terraform apply -auto-approve` | Zastosuj bez pytania |
| `tfd` | `terraform destroy` | Zniszcz infrastrukturę |
| `tfda` | `terraform destroy -auto-approve` | Zniszcz bez pytania |
| `tff` | `terraform fmt` | Formatuj kod |
| `tfp` | `terraform plan` | Pokaż plan |
| `tfv` | `terraform validate` | Waliduj konfigurację |
| `tfs` | `terraform state` | Zarządzanie stanem |
| `tfo` | `terraform output` | Pokaż outputs |
| `tfr` | `terraform refresh` | Odśwież stan |

---

## 🐳 **Docker Aliases (docker plugin)**

### **Podstawowe Docker:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `d` | `docker` | Docker command |
| `dbl` | `docker build` | Buduj obraz |
| `dcln` | `docker container prune` | Wyczyść kontenery |
| `dclnf` | `docker container prune -f` | Wyczyść force |
| `dib` | `docker image build` | Buduj obraz |
| `dii` | `docker image inspect` | Inspect obrazu |
| `dils` | `docker image ls` | Lista obrazów |
| `dirm` | `docker image rm` | Usuń obraz |
| `dit` | `docker image tag` | Taguj obraz |

### **Docker Containers:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `dps` | `docker ps` | Działające kontenery |
| `dpsa` | `docker ps -a` | Wszystkie kontenery |
| `drm` | `docker rm` | Usuń kontener |
| `drmf` | `docker rm -f` | Usuń force |
| `dst` | `docker start` | Uruchom kontener |
| `dstp` | `docker stop` | Zatrzymaj kontener |
| `drs` | `docker restart` | Restart kontener |

### **Docker Compose:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `dco` | `docker compose` | Docker Compose |
| `dcb` | `docker compose build` | Buduj |
| `dcd` | `docker compose down` | Stop i usuń |
| `dce` | `docker compose exec` | Wykonaj w kontenerze |
| `dcl` | `docker compose logs` | Pokaż logi |
| `dcps` | `docker compose ps` | Status |
| `dcr` | `docker compose run` | Uruchom service |
| `dcu` | `docker compose up` | Uruchom |
| `dcud` | `docker compose up -d` | Uruchom w tle |

---

## ☸️ **Kubernetes Aliases (kubectl plugin)**

### **Podstawowe kubectl:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `k` | `kubectl` | Główne polecenie |
| `ka` | `kubectl apply` | Zastosuj manifesty |
| `kaf` | `kubectl apply -f` | Zastosuj z pliku |
| `kd` | `kubectl describe` | Opis zasobu |
| `kdel` | `kubectl delete` | Usuń zasób |
| `ke` | `kubectl edit` | Edytuj zasób |
| `kg` | `kubectl get` | Pobierz zasoby |
| `kl` | `kubectl logs` | Pokaż logi |

### **Pods & Deployments:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `kgp` | `kubectl get pods` | Lista podów |
| `kgpa` | `kubectl get pods -A` | Wszystkie pody |
| `kgd` | `kubectl get deployments` | Deploymenty |
| `kgs` | `kubectl get services` | Serwisy |
| `kgn` | `kubectl get nodes` | Nody |
| `kdp` | `kubectl describe pod` | Opis poda |
| `kdd` | `kubectl describe deployment` | Opis deploymentu |
| `kds` | `kubectl describe service` | Opis serwisu |

### **Exec & Port Forward:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `kex` | `kubectl exec -it` | Wejdź do poda |
| `kpf` | `kubectl port-forward` | Port forwarding |
| `ktop` | `kubectl top` | Metryki użycia |

---

## 🔀 **Git Aliases (git plugin)**

### **Podstawowe Git:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `g` | `git` | Git command |
| `ga` | `git add` | Dodaj pliki |
| `gaa` | `git add --all` | Dodaj wszystko |
| `gc` | `git commit` | Commit |
| `gcm` | `git commit -m` | Commit z wiadomością |
| `gca` | `git commit -a` | Commit all |
| `gcam` | `git commit -a -m` | Commit all z msg |

### **Branches & Status:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `gb` | `git branch` | Branche |
| `gco` | `git checkout` | Przełącz branch |
| `gcb` | `git checkout -b` | Nowy branch |
| `gst` | `git status` | Status |
| `gd` | `git diff` | Różnice |
| `gl` | `git log` | Historia |
| `glo` | `git log --oneline` | Krótka historia |

### **Remote & Pull/Push:**
| Alias | Polecenie | Opis |
|-------|-----------|------|
| `gp` | `git push` | Wyślij zmiany |
| `gl` | `git pull` | Pobierz zmiany |
| `gf` | `git fetch` | Fetch |
| `grh` | `git reset --hard` | Hard reset |
| `grhh` | `git reset --hard HEAD` | Reset do HEAD |

---

## 🔧 **Własne Aliasy DevOps**

### **Dodaj do ~/.zshrc (na końcu):**
```bash
# Custom DevOps aliases
alias tf='terraform'
alias tfws='terraform workspace'
alias tfwsl='terraform workspace list'
alias tfwss='terraform workspace select'

# AWS shortcuts  
alias awsid='aws sts get-caller-identity'
alias awsregion='aws configure get region'
alias awsprofile='echo $AWS_PROFILE'

# Docker shortcuts
alias dps='docker ps'
alias dimg='docker images'
alias dclean='docker system prune -f'

# Kubernetes shortcuts
alias kns='kubectl get namespaces'
alias kctx='kubectl config current-context'
alias kgpw='kubectl get pods -o wide'

# Terraform + AWS combo
alias tfinit='terraform init && terraform plan'
alias tfcost='terraform plan -out=plan.out && terraform show -json plan.out'
```

### **Zastosuj nowe aliasy:**
```bash
source ~/.zshrc
```

---

## 📋 **Quick Reference Commands**

### **Sprawdź aktywne aliasy:**
```bash
# Wszystkie terraform aliasy
alias | grep tf

# Wszystkie docker aliasy  
alias | grep docker

# Wszystkie kubectl aliasy
alias | grep kubectl

# Pokaż definicję konkretnego aliasu
type tfa
```

### **Sprawdź które pluginy są aktywne:**
```bash
echo $plugins
```

### **Lista dostępnych pluginów:**
```bash
ls ~/.oh-my-zsh/plugins/ | grep -E "(terraform|docker|kubectl|aws|helm)"
```

---

## 🎯 **Najbardziej przydatne dla DevOps:**

### **Daily terraform workflow:**
```bash
tfi           # terraform init
tfp           # terraform plan  
tfa           # terraform apply
tfo           # terraform output
tfs list      # terraform state list
```

### **Daily docker workflow:**
```bash
dps           # docker ps
dimg          # docker images
dcb           # docker compose build
dcu           # docker compose up
dcd           # docker compose down
```

### **Daily kubernetes workflow:**
```bash
kgp           # kubectl get pods
kgd           # kubectl get deployments  
kgs           # kubectl get services
kl pod-name   # kubectl logs pod-name
kex pod-name  # kubectl exec -it pod-name
```

---

**💡 Pro tip:** Użyj `type alias_name` żeby zobaczyć co robi konkretny alias!

**🚀 Printuj sobie tę ściągę i miej pod ręką podczas pracy!**