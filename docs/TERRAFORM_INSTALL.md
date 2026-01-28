# Terraform 설치 가이드 (맥북)

## 방법 1: Homebrew 사용 (권장)

### 1. Terraform 설치
```bash
brew install terraform
```

### 2. 설치 확인
```bash
terraform version
```

설치가 완료되면 다음과 같은 출력이 나타납니다:
```
Terraform v1.x.x
```

## 방법 2: tfenv 사용 (버전 관리가 필요한 경우)

여러 버전의 Terraform을 관리하고 싶다면 tfenv를 사용할 수 있습니다.

### 1. tfenv 설치
```bash
brew install tfenv
```

### 2. Terraform 설치 (최신 버전)
```bash
tfenv install latest
```

### 3. 특정 버전 설치
```bash
tfenv install 1.6.0
```

### 4. 사용할 버전 설정
```bash
tfenv use 1.6.0
```

## 설치 후 확인

터미널에서 다음 명령어로 설치를 확인하세요:

```bash
terraform version
```

## 문제 해결

### "command not found: terraform" 오류

1. **PATH 확인**
   ```bash
   echo $PATH
   ```
   
2. **Homebrew 경로 추가** (필요한 경우)
   ```bash
   # Apple Silicon (M1/M2) 맥북인 경우
   echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
   source ~/.zshrc
   
   # Intel 맥북인 경우
   echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zshrc
   source ~/.zshrc
   ```

3. **터미널 재시작**
   - 터미널을 완전히 종료하고 다시 열기

### Homebrew가 없는 경우

Homebrew를 먼저 설치하세요:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Apple Silicon (M1/M2) 맥북의 경우 추가 설정이 필요할 수 있습니다:
```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
source ~/.zshrc
```

## 다음 단계

Terraform 설치가 완료되면:

```bash
# 루트 디렉토리에서 실행
terraform init
terraform plan
terraform apply
```
