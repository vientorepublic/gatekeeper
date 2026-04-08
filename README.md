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
- 프론트엔드 상세 설정/개발/빌드 검증: `gatekeeper-frontend/README.md`

## 개발 워크플로우

1. 각 서브모듈에서 기능 개발 및 커밋 수행
2. 루트 저장소에서 서브모듈 포인터 업데이트 커밋
3. 루트 기준으로 배포/릴리즈 버전 관리
