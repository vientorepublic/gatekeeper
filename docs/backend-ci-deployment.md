# 백엔드 CI와 자동 배포

루트 `vientorepublic/gatekeeper` 저장소의 워크플로우입니다. 자식 저장소 main 푸시만으로는
실행되지 않습니다. 검증된 자식 커밋을 루트 gitlink에 반영하고 루트 main으로 병합해야 합니다.

## 실행 흐름

- 모든 PR과 merge queue: `quality.yml`에서 루트에 고정된 두 앱을 `npm ci`로 설치하고
  린트, 타입 검사, 빌드, 단위 테스트를 실행합니다. 백엔드 통합 테스트와 프론트엔드
  Cloudflare/Node 빌드도 포함합니다. 백엔드 린트가 자동 수정한 경우에도 실패합니다.
- main push: 같은 품질 검사를 다시 통과한 후 WireGuard를 연결합니다.
  SSH 키로 `root@10.20.0.1`에 접속하여 `/root/Gatekeeper`에서 해당 main SHA를
  fast-forward하고, 그 커밋의 백엔드 gitlink를 체크아웃합니다.
- `docker compose build backend` 성공 후 `up --detach --no-deps --wait`로 백엔드만
  교체하고 호스트의 `http://127.0.0.1:10001/health` 응답을 확인합니다.
  DB·Redis·프론트엔드 재생성이나 볼륨 삭제는 하지 않습니다.
- GitHub 동시 실행 그룹과 서버 `flock`으로 배포를 직렬화합니다. 대기 중 main이 갱신되면
  오래된 실행은 건너뜁니다. 실패·취소 시에도 터널과 임시 키를 정리합니다.

## GitHub 설정

루트 저장소 **Settings → Secrets and variables → Actions**에 등록합니다.

- Secret `VULTR_WIREGUARD`: runner용 전체 `wg-quick` 설정 원문. `[Interface]`의
  `PrivateKey`, `Address`, `[Peer]`의 서버 `PublicKey`, 공개 `Endpoint`를 포함합니다.
  `AllowedIPs = 10.20.0.1/32`, `PersistentKeepalive = 25`를 권장합니다.
  서버 peer에도 runner의 주소와 공개키가 등록되어 있어야 합니다. 인터넷 기본 경로를
  바꾸는 `0.0.0.0/0`는 사용하지 마세요. `DNS` 항목은 불필요하며 runner의
  `resolvconf` 의존성을 만들 수 있으므로 생략하세요. 설정은 실행 권한이 있는 민감 자료입니다.
- Secret `VULTR_SSH_SECRET`: root의 `authorized_keys`에 대응하는 암호 없는 SSH
  개인키 원문. 공개키나 파일 경로가 아닙니다. 전용 배포 키를 사용합니다.
- Variable `VULTR_SSH_KNOWN_HOSTS`: 신뢰할 수 있는 서버 콘솔에서 확인한 SSH host key.
  `10.20.0.1 ssh-ed25519 <server-host-public-key>` 형식입니다. 서버의
  `/etc/ssh/ssh_host_ed25519_key.pub`를 기준으로 준비합니다. 실행 중 얻은 미검증 키로
  대체하지 않습니다. host key 변경 시 이 변수도 검증 후 갱신합니다.
- Secrets `BACKEND_READ_KEY`, `FRONTEND_READ_KEY`: 각 앱 저장소의 `gatekeeper-root-ci`
  읽기 전용 deploy key에 대응하는 SSH 개인키입니다. 루트 checkout은 기본
  `GITHUB_TOKEN`의 `contents: read`를 사용하고, 각 앱 checkout에는 해당 앱 전용 키만
  전달합니다. 기본 토큰의 저장소 범위를 확장하거나 운영 서버 키를 재사용하지 않습니다.
  초기 설정은 gh로 완료했습니다. 키 교체 시 해당 앱 deploy key와 루트 secret을 함께
  갱신해야 합니다. PAT는 필요하지 않습니다.

PR 작업에는 WireGuard·SSH 배포 비밀값을 전달하지 않습니다. 읽기 키는 checkout에만
사용하고 Git 설정에 저장하지 않습니다. fork PR·Dependabot PR 등 비밀값을 받지 못하는
실행은 비공개 서브모듈을 가져올 수 없어 실패합니다. 이 경우 신뢰한 코드를 내부
브랜치로 가져와 검사하며, `pull_request_target`으로 비밀값을 노출하는 방식은 사용하지 않습니다.

## 필수 병합 차단 설정

2026-10-23 확인 시 세 저장소 모두 비공개이며, GitHub API는 루트의 rulesets와
main branch protection 조회에 `Upgrade to GitHub Pro or make this repository public`
403을 반환했습니다. 현재 상태에서는 강제 병합 차단을 활성화할 수 없습니다.
지원 요금제로 전환하거나 의도적으로 공개 범위를 변경한 뒤 아래 규칙을 설정해야 합니다.
이번 작업에서는 요금제·공개 범위를 변경하지 않았습니다.

워크플로우 파일만으로는 GitHub의 병합 버튼이 차단되지 않습니다. 워크플로우를 반영하고
PR에서 한 번 실행한 후, 루트 저장소 **Settings → Rules → Rulesets**에서 main과 dev를
대상으로 활성 브랜치 규칙을 설정하세요. 기존 규칙의 리뷰·서명 요구 사항은 유지합니다.

1. PR을 통한 변경을 요구합니다.
2. **Require status checks to pass**에서 `PR quality gate` 검사를 선택합니다.
   reusable workflow의 호출 경로가 표시되면 PR의 Quality 실행에 속한 검사를 선택합니다.
3. 병합 전 최신 브랜치 기준 검사를 요구하거나 merge queue를 사용합니다.
4. 일반 사용자·관리자의 우회 권한과 직접 push 예외를 허용하지 않습니다.

`PR quality gate`는 `always()`로 실행되어 어느 앱의 검사라도 실패·취소·생략되면
실패합니다. 경로 필터 없이 실행하며 merge queue의 `merge_group` 이벤트도 처리합니다.
자식 저장소 PR 자체를 차단하려면 해당 저장소에도 CI와 별도의 보호 규칙이 필요합니다.
루트 검사는 루트 PR이 선택한 gitlink 조합을 검증합니다.

## 서버 준비와 운영 제한

- Linux, Bash, Git, `flock`, curl, Docker Engine과 `--wait`를 지원하는 Compose plugin을
  설치하고 root SSH 키 접속을 허용해야 합니다. SSH 포트는 22입니다.
- `/root/Gatekeeper`는 루트 저장소 clone이며 `main` 브랜치에 있어야 합니다.
  기본 경로가 없다면 홈 디렉터리 3단계 이내에서 이름이 대소문자 구분 없이 Gatekeeper인
  Git/Compose clone을 찾습니다. 후보가 정확히 하나일 때만 사용하며 여러 clone 중 임의로
  선택하거나 새로 clone하지 않습니다.
  origin fetch와 백엔드 서브모듈 fetch가 비대화식으로 가능해야 합니다.
  서버의 로컬 수정이나 분기된 이력은 자동 초기화하지 않고 배포를 실패시킵니다.
- 서버의 `.gitmodules`와 submodule 등록을 먼저 확인합니다. 로컬 개발 환경의 등록 이름
  불일치는 이번 작업에서 수정하지 않았습니다.
- 기존 Compose의 두 앱 `.env`, `gateway_shared_network`, 정상 DB·Redis가 필요합니다.
  환경 파일은 Git 추적에서 제외하세요. `config --quiet`는 설정 내용을 출력하지 않습니다.
  Compose 예제 DB 암호는 운영용으로 교체하고 `DB_SYNCHRONIZE=false`를 유지합니다.
- 루트 gitlink는 두 앱의 검증된 `v1.0.0` main 커밋을 선택합니다. 앱의 새 변경을
  배포하려면 자식 저장소에서 먼저 검증·공개하고 루트 포인터를 갱신해야 합니다.
- `/health`는 프로세스 응답 확인이며 DB·Redis·OAuth·업스트림 readiness를 보증하지
  않습니다. 재시작 중 중단이 발생할 수 있고 자동 rollback은 구현하지 않습니다.
  시작 시 migration이 실행될 수 있으므로 DB 백업과 스키마 호환성을 사전에 확인하세요.
  실패하면 Actions 오류와 서버 상태를 확인하고 호환 가능한 커밋을 PR로 재배포합니다.

이 문서는 워크플로우 설치 절차이며 즉시 운영 배포나 GitHub Release 발행을 수행하지 않습니다.
릴리즈 절차는 [GitHub·릴리즈 워크플로우](github-release-workflow.md)를 따릅니다.

참고: [GitHub 필수 검사 문제 해결](https://docs.github.com/en/pull-requests/how-tos/merge-and-close-pull-requests/troubleshooting-required-status-checks),
[Docker Compose up](https://docs.docker.com/reference/cli/docker/compose/up/).
