# 🍩 Donuts-Store - Guia de Inicialização

Este tutorial explica como configurar e rodar o projeto Django da Donuts-Store em sua máquina local.

---

## 1. Crie o ambiente virtual

### Linux/macOS

```bash
python3 -m venv .venv
```

### Windows

```bash
python -m venv .venv
```

---

## 2. Ative o ambiente virtual

### Linux/macOS

```bash
source .venv/bin/activate
```

### Windows (CMD)

```cmd
.venv\Scripts\activate.bat
```

### Windows (PowerShell)

```powershell
.venv\Scripts\Activate.ps1
```

---

## 3. Instale os pacotes necessários

Certifique-se de estar na raiz do projeto (onde está o arquivo `requirements.txt`).

```bash
pip install -r requirements.txt
```

---

## 4. Aplique as migrations

Certifique-se de estar na pasta src/ (onde está o arquivo `manage.py`).

```bash
python manage.py migrate
```

---

## 5. Rode o servidor

```bash
python manage.py runserver
```

---

Agora o projeto estará disponível em:

```
http://127.0.0.1:8000/
```

---
