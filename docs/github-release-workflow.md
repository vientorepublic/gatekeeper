# GitHub·브랜치·배포 릴리즈 절차

이 문서는 [AGENTS.md](../AGENTS.md) 4–7절의 실행 순서를 구체화합니다. [기능 워크플로우](development-workflow.md)의 수용 기준과 검증을 먼저 충족해야 합니다. 루트와 두 앱은 각기 다른 GitHub 저장소이므로 명령의 대상과 커밋을 항상 명시합니다.

## 1. 명령의 범위

GitHub의 PR·이슈·Renovate PR/대시보드·검사·Actions·릴리즈 조회와 변경은 `gh` CLI로 수행합니다. 필요한 전용 명령이 없으면 `gh api`를 사용합니다. 브라우저·직접 HTTP 호출로 우회하지 않습니다. 로컬 브랜치·커밋·diff·fetch/pull/push·gitlink 조작은 `git`을 사용합니다.

사용자가 “배포해줘”라고 요청하면 해당 범위에 대해 버전 결정 → 설치/lockfile 검증 → 코드 검증 → 커밋/푸시 → `feat/* → dev → main` PR 병합 → GitHub Release 생성 → 이력에 맞는 `main → dev` 동기화 → 로컬 `dev` 갱신까지 수행합니다. 이 단계마다 같은 승인을 다시 묻지 않습니다. 기능 구현만 요청받았다면 자동으로 main에 병합하거나 릴리즈하지 않습니다. 이 문서의 작성·수정 요청 자체도 배포 요청은 아닙니다.

프로젝트 전체 배포는 변경된 앱들의 버전 릴리즈와 루트 조합 릴리즈를 포함합니다. 특정 앱만 요청되면 해당 앱과 그 최종 포인터를 반영할 루트 범위로 제한하고, 변경 없는 앱의 버전을 억지로 올리거나 다시 릴리즈하지 않습니다. 앱 한정 배포에서 별도 루트 릴리즈는 요청된 경우에 생성합니다. 대상 환경·서비스가 여러 개라 의도가 불분명하면 그 선택만 질문하고 가능한 준비 작업은 계속합니다.

GitHub Release 생성과 실제 서비스 배포 성공은 구분합니다. 저장소의 Actions·외부 호스팅 트리거를 `gh`와 프로젝트 설정으로 확인하고, 검증된 배포 경로를 실행·관찰합니다. 배포 경로·접근 권한이 없으면 릴리즈 URL과 함께 실제 배포가 차단된 이유를 보고합니다. 요청을 npm 패키지 게시나 운영 데이터 삭제까지 확대하지 않습니다.

## 2. 개발 시작: 최신 dev에서 피처 분기

1. 지침·공유 메모리·루트/앱의 상태·remotes·기존 diff·gitlink를 확인합니다. 기존 미커밋 작업은 보존합니다. 현재 진행 중인 `codex/*` 등 브랜치는 강제로 변경하지 않고, 다음 새 작업부터 `feat/<topic>`을 적용합니다.
2. `gh auth status`로 인증 상태를 확인하고 각 저장소의 `OWNER/REPO`, `dev`, `main`, 브랜치 보호·병합 전략을 조회합니다. PR·Release 등 지원 명령에는 `--repo OWNER/REPO`를 지정합니다. `gh api`는 해당 옵션이 없으므로 `repos/OWNER/REPO/...` endpoint나 명시적인 GraphQL repository 변수를 사용합니다. `gh auth status`는 저장소 선택이 없는 명령입니다. 자격증명은 출력·메모리에 기록하지 않습니다.
3. 작업 트리가 안전하면 `git fetch origin --prune`, `git switch dev`, `git pull --ff-only origin dev`로 로컬 dev를 최신화합니다. 로컬 dev가 없고 원격 dev가 있으면 원격을 추적하는 dev를 만듭니다. 로컬이 앞서거나 분기되어 있으면 내용을 조사하고 보존하며, reset/강제 push로 맞추지 않습니다.
4. 원격 dev가 실제로 없으면 확인된 main SHA를 기준으로 `gh api`의 Git refs API로 dev를 만든 뒤 추적합니다. 이는 실제 브랜치/공개 작업 범위에서 수행하며, 문서 수정만 하면서 원격 브랜치를 만들지 않습니다. 기존 이력이 있으면 먼저 조정하고 main이 없다는 이유로 임의 기준을 정하지 않습니다.
5. 최신 dev에서 `git switch -c feat/<topic>`으로 분기합니다. 루트와 변경 앱 각각에 적용하되, 앱들이 독립 저장소라는 사실을 유지합니다. 기능 완료 전까지 공유 dev/main에 직접 커밋하지 않습니다.

## 3. 버전·커밋·피처에서 dev로 병합

1. AGENTS.md의 호환성 기준으로 변경 앱별 버전을 정합니다. integration 기준은 dev이며 이미 공개된 main 버전·태그와 충돌하지 않아야 합니다. 같은 변경의 충분한 미출시 버전 범프는 재사용합니다.
2. 최종 manifest 변경 후 앱 안에서 `npm i`, lockfile checksum 기록, `npm ci`, 버전 일치·checksum 불변 확인, 필수 검증을 순서대로 수행합니다. 체크를 약화하거나 lockfile을 삭제해 통과시키지 않습니다.
3. 의도한 파일·manifest·lockfile을 함께 검토하고 해당 앱 피처에서 커밋·푸시합니다. 서명 정책을 지키며 `git diff --cached --check`를 확인합니다.
4. `gh pr list/view`로 기존 피처 PR을 확인해 재사용하거나 `gh pr create --base dev --head feat/<topic>`으로 생성합니다. 본문은 파일로 작성해 `--body-file`로 전달합니다. PR을 생성하면 현재 작업에 PR URL도 첨부합니다.
5. `gh pr checks`와 `gh pr view`로 체크·리뷰·병합 가능 상태와 head SHA를 확인하고 `gh pr merge --match-head-commit <verified-head-sha>`로 병합합니다. 피처→dev는 정책에 따라 squash/merge를 선택합니다. 체크가 없으면 “CI 통과”로 기록하지 말고 로컬 근거와 CI 부재를 구분합니다.
6. merge queue/auto-merge가 걸렸다면 실제 `MERGED`와 merge SHA를 확인할 때까지 완료로 처리하지 않습니다. 병합 결과를 fetch하고 dev에 통합된 최종 상태를 검증합니다. 충돌 해결·다른 변경의 통합으로 패키지 상태가 바뀌면 설치 게이트와 영향받는 검증을 다시 실행합니다.

일반 개발은 이 단계에서 dev로 돌아와 최신화하고 종료할 수 있습니다. 배포 요청은 아래 main 승격과 Release까지 이어집니다. 필요한 리뷰·체크가 차단되면 해당 단계에서 이유와 재개 조건을 남기며, `--admin`이나 보호 해제로 우회하지 않습니다.

## 4. dev에서 main으로 승격

1. `gh`로 dev와 main의 전체 차이를 확인합니다. dev에는 다른 기능이 이미 포함될 수 있으므로 배포 범위에 맞는지 확인합니다. 지정 범위를 넘어선 변경을 묵시적으로 배포하거나 임의 cherry-pick으로 표준 흐름을 우회하지 않습니다.
2. `gh pr create --base main --head dev`로 승격 PR을 만들거나 기존 PR을 재사용합니다. 버전, 검증 결과, 변경 계약·migration·복구 방법을 본문에 포함합니다.
3. 피처 PR과 동일하게 체크·리뷰·현재 head SHA를 확인합니다. dev→main은 merge commit 등 양쪽 조상을 보존하는 전략을 사용합니다. 반복 squash/rebase로 공유 브랜치 이력을 분리하지 않습니다. 저장소 설정이 이를 막으면 설정 충돌을 보고하고 해결 전 릴리즈하지 않습니다.
4. `gh pr view`로 실제 병합 상태와 merge SHA를 확인하고 fetch합니다. 최종 main 커밋의 버전·lockfile·계약과 검증된 트리가 일치하는지 확인합니다. 부모가 추가되거나 최종 tree가 달라졌으면 영향 검증을 갱신합니다. 이후 main이 전진해도 릴리즈는 이번에 검증한 전체 SHA에 고정합니다.

## 5. 앱 릴리즈 → 루트 포인터·릴리즈

1. 변경된 각 앱의 최종 main SHA가 원격 main에서 접근 가능한지 확인합니다. 앱의 manifest/root-lock 버전이 같아야 합니다. 버전과 일치하는 기존 태그 규칙을 따르며, 규칙이 없으면 `vX.Y.Z`를 사용합니다.
2. `gh release list/view`와 `gh api`로 동일 태그·릴리즈의 존재와 실제 태그 대상 커밋을 확인합니다. 기존 태그가 다른 SHA면 덮어쓰거나 옮기지 않습니다. 같은 SHA·같은 버전의 정상 릴리즈라면 재사용합니다. 요청 타임아웃 후에도 먼저 존재 여부를 확인해 중복 생성을 피합니다.
3. 검증 결과·변경 사항·호환성·migration·검증 한계가 포함된 릴리즈 노트 파일을 만들고 `gh release create <tag> --repo <owner/repo> --target <full-main-sha> --title <title> --notes-file <notes-file>`로 정식 릴리즈를 게시합니다. 기존 태그를 사용하면 대상 확인 후 `--verify-tag`를 추가합니다. `--target`만으로 이미 존재하는 태그가 재지정되지는 않습니다. draft/prerelease는 명시된 요청일 때 사용합니다.
4. `gh release view`로 게시 상태·태그·URL을 확인하고 `gh api`로 태그가 최종 main SHA로 해석되는지 검증합니다. annotated tag라면 tag object를 따라 실제 commit까지 확인합니다. 앱 버전·main SHA·태그·Release URL을 기록합니다.
5. 앱 릴리즈가 확인된 뒤 루트 피처에서 해당 main SHA만 gitlink에 반영합니다. 자식 dev로 복귀하기 전에 main SHA를 checkout해 stage하거나 정확한 gitlink를 검증해 반영하고, 앱 미커밋 작업은 포함하지 않습니다. 루트에는 별도 package/version을 만들지 않습니다.
6. 루트 피처 커밋·`git push --recurse-submodules=check` → `feat/* → dev` PR → `dev → main` PR 순으로 처리합니다. 각 단계의 최종 tree에서 gitlink가 릴리즈된 앱 SHA와 같은지 확인합니다. 변경 없는 앱은 검증된 기존 포인터를 유지합니다.
7. 프로젝트 전체 배포에서는 최종 루트 main SHA에 조합 Release를 게시합니다. 기존 루트 태그 규칙을 우선 사용하고, 없으면 충돌 없는 `release-YYYYMMDD.N`을 사용합니다. 이는 npm SemVer가 아닙니다. 노트에 루트 SHA, 각 앱의 버전·SHA·태그·URL, 실제 배포 상태를 포함합니다. 동일 배포 재시도에서는 기존 조합 릴리즈를 재사용합니다.

앱이 먼저 공개되고 루트 또는 서비스 배포가 실패하면 부분 완료로 기록합니다. 이미 공개된 태그/릴리즈를 삭제하거나 강제로 바꾸지 말고, 남은 단계에서 재개합니다. 미래 배포 검증 결과를 이미 게시된 소스 노트의 사실로 선기재하지 않습니다.

## 6. main을 dev에 동기화하고 로컬 개발 상태 복원

1. 모든 릴리즈의 불변 SHA와 URL을 먼저 기록하고 fetch합니다. 앱과 루트 각각에서 커밋 관계와 파일 차이를 별도로 확인합니다. `origin/main...origin/dev` 순서의 `git rev-list --left-right --count`는 main 전용·dev 전용 커밋 수이며, `git log --left-right --oneline`으로 정체를 확인하고 `git diff --stat origin/main origin/dev`로 실제 내용 차이를 확인합니다.
   - 두 tip이 같으면 완료입니다.
   - main이 이미 dev의 조상이면 추가 동기화를 하지 않습니다. dev 전용 커밋이 실제 미출시 변경인지, 파일 내용이 같은 병합 기록인지 분류합니다.
   - dev가 검증된 main의 조상이면 새 커밋을 만드는 역방향 병합보다 원격 dev의 fast-forward를 우선합니다. 보호 규칙과 필수 검증·리뷰가 허용할 때만 `gh api`의 `repos/OWNER/REPO/git/refs/heads/dev` PATCH에 검증한 main SHA와 boolean `force=false`를 전달합니다. 이는 기존 커밋으로 ref를 전진시키는 예외이며 공유 브랜치 직접 커밋을 허용하지 않습니다. 직전 원격 tip을 다시 확인하고, 직후 dev가 목표 SHA인지 확인합니다. 예상하지 못한 변경이 있으면 중단하고 새 이력을 분류하며 강제로 덮어쓰지 않습니다.
   - 보호 규칙이 PR을 요구하거나 양쪽 이력이 갈라졌으면 전체 diff를 확인한 뒤 `main → dev` PR을 한 번 병합합니다. 조상을 보존하고 정상 검사·리뷰를 따릅니다. PR 병합 방식에서는 dev에 내용 차이 없는 병합 커밋 하나가 남을 수 있음을 보고합니다.

   GitHub의 ahead/behind 숫자를 없애려고 양방향 PR 병합을 반복하면 새 병합 커밋이 계속 생깁니다. 배지를 없애기 위한 빈 커밋·main 승격·재배포·릴리즈를 만들지 않고, 이미 공개된 dev를 main으로 reset/강제 갱신하지 않습니다. 기존 병합 기록을 제거하려고 태그나 루트 핀을 변경하지 않습니다.
2. 변경된 앱부터 루트까지 작업 트리가 안전한지 확인한 뒤 `git fetch origin --prune`, `git switch dev`, `git pull --ff-only origin dev`를 수행합니다. `dev == origin/dev`, main의 dev 포함 여부, 원격 main/dev의 앞섬·뒤처짐 수와 파일 차이를 모두 검증합니다. 로컬 main을 최신화할 때도 ff-only로 처리하며 분기 이력을 강제로 덮어쓰지 않습니다.
3. 돌아온 dev의 manifest·lockfile이 설치 당시 상태와 다르면 각 앱에서 `npm ci`로 node_modules를 갱신합니다. 이것은 피처 커밋 전의 `npm i → npm ci` 검증을 대체하지 않습니다. 설정 예제·개발 서비스 요구 변경을 확인하되 기존 `.env`나 데이터를 덮어쓰지 않습니다.
4. 루트 릴리즈의 포인터는 앱 main SHA로 유지합니다. 최신 자식 dev checkout의 SHA가 다르면 루트에서 gitlink 변경으로 표시될 수 있으므로, 배포 포인터와 개발 checkout의 차이로 기록합니다. 이를 지우려고 자식을 과거 핀으로 되돌리거나 dev SHA를 main 릴리즈 포인터에 자동 반영하지 않습니다. 정확한 배포 트리 재현은 별도의 깨끗한 checkout에서 수행합니다.
5. 각 저장소의 현재 브랜치·HEAD·추적 상태·남은 변경, 앱 설치 상태, PR·Release URL, 서비스 배포 결과를 보고합니다. dev 복귀나 동기화가 차단되면 “개발 환경 복원 완료”로 표시하지 않습니다. 기존 피처 브랜치는 별도 요청이나 명확한 정리 정책 없이 삭제하지 않습니다.

완료 조건은 **검증된 코드 + 요청 범위의 실제 병합 + GitHub Release 확인 + 로컬 최신 dev 복귀**입니다. 실제 환경 배포까지 확인해야 `deployed`로 표시하고, Release 생성까지만 완료되었으면 `released`로 기록합니다.
