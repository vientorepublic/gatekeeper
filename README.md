# Gatekeeper

Gatekeeper는 API Gateway 백엔드와 운영 콘솔 프론트엔드로 구성된 멀티 리포지토리 프로젝트입니다.

## 프로젝트 개요

- 백엔드: NestJS 기반 API Gateway
- 프론트엔드: SvelteKit 기반 인증/키 관리 콘솔
- 인증 체계: OAuth2 + 내부 JWT + API Key
- 운영 목적: 네임스페이스 단위 라우팅, 인증, API Key 관리, 게이트웨이 관측

## 저장소 구조

루트 저장소는 메타 리포지토리이며, 실제 애플리케이션 코드는 아래 Git 서브모듈로 관리됩니다.

- `gatekeeper-backend/`: API Gateway 서버
- `gatekeeper-frontend/`: 웹 콘솔

## 시작하기

이미 클론된 경우:

```bash
git submodule update --init --recursive
```

새로 클론하는 경우:

```bash
git clone --recurse-submodules <root-repo-url>
```

## 문서 가이드

- 전체 아키텍처/역할/운영 관점 설명: 이 문서
- 백엔드 상세 설정/엔드포인트/관측/테스트: `gatekeeper-backend/README.md`
- 프론트엔드 상세 설정/개발/빌드 검증/Cloudflare Pages 배포: `gatekeeper-frontend/README.md`
- 공통 에이전트 작업 지침: [AGENTS.md](AGENTS.md)
- 에이전트 공유 기억과 구조 분석: [agent_memories/README.md](agent_memories/README.md)

## 배포

백엔드는 루트 main push 시 WireGuard와 SSH로 자동 배포하도록 구성합니다.
시크릿·서버 준비와 PR 필수 검사 설정은 [백엔드 CI·배포 문서](docs/backend-ci-deployment.md)를 따르세요.

프론트엔드는 앱 저장소의 `main` 푸시를 GitHub Actions가 빌드해 기존 Cloudflare Pages 프로젝트로 배포합니다. Cloudflare의 Git 연결은 해제되어 비-main 푸시가 skipped 기록도 만들지 않습니다. `production` 환경의 Secret과 공개 빌드 변수 설정은 [프론트엔드 배포 문서](gatekeeper-frontend/docs/deployment.md#github-actions-프로덕션-배포)를 따르세요.

## 개발 워크플로우

기능 추가·수정·삭제는 [상세 개발 워크플로우](docs/development-workflow.md)를 따릅니다.
여러 모듈·저장소 또는 공개 계약·인증·데이터에 영향을 주는 작업은
[작업 기록 템플릿](agent_memories/templates/change-template.md)을 사용합니다.

1. `AGENTS.md`와 공유 기억을 읽고 기존 변경을 확인한 뒤 현재/목표 동작·범위·수용 기준 정의
2. 사용처와 API·권한·데이터·설정 계약을 조사하고 유형별 구현·전환 순서 결정
3. 제공자와 소비자를 함께 수정하고 테스트·문서·불필요한 참조 정리
4. 변경한 앱의 버전·`npm i`·`npm ci`·관련 검증을 완료하고 수용 기준별 근거 기록
5. 로컬 검증 완료와 공개·배포 상태를 구분해 보고하고 공유 기억 갱신
6. 커밋·푸시 작업 시 자식 저장소를 먼저 공개하고 원격 SHA 확인 후 루트 포인터를 마지막에 반영

GitHub 관련 작업은 `gh` CLI를 사용합니다. 새 작업은 최신 `dev`에서 `feat/<topic>`을
생성하고 `feat → dev → main` PR 순서로 병합합니다. 배포 요청은 버전·lockfile·검증,
커밋·푸시·병합과 최종 main SHA에 대한 GitHub Release 생성까지 포함합니다.
완료 후 `main → dev` 동기화와 로컬 최신 dev 복귀·의존성 갱신을 수행합니다.
일반 개발은 dev 통합까지만 진행할 수 있습니다. 상세 범위와 앱·루트 처리 순서는
[GitHub·브랜치·릴리즈 절차](docs/github-release-workflow.md)를 따르세요.

앱 버전은 각 앱의 `package.json`에서 독립적으로 관리합니다. 루트는 배포 조합을
정확한 커밋 포인터로 기록하며 별도의 Node.js 패키지 버전은 없습니다.
상세 버전 기준과 lockfile·포인터 검증 절차는 `AGENTS.md`를 따르세요.
