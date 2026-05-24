---
name: circleci-investigate
description: >
  CircleCI上で動いたジョブ・ワークフロー・パイプラインを調査する。
  生stepログ（成功/失敗を問わない）、テスト結果、artifact一覧、リソース使用量、状態確認、
  ワークフロー内のジョブ一覧を、ジョブURL・パイプラインURL・ブランチ名+ジョブ名のいずれからでも取得できる。
  「CircleCIのログ見たい」「失敗したジョブの原因調べて」「circleci.com の URL を貼った」
  「CIのテスト結果」「artifactのDL URL」「ジョブのリソース使用量」などのリクエストで使用。
---

# circleci-investigate

CircleCI のジョブ・ワークフロー・パイプラインを調査するための Skill。

## Out of scope

- 書き込み操作（rerun / cancel / approve / ロールバック実行）は扱わない
- 認証情報のセットアップ（事前に環境変数 `CIRCLECI_TOKEN` が export されている前提）
- config.yml の検証・編集、フレイキーテストの解析、実行中ジョブのリアルタイム表示

## Usage

```bash
<SKILL_DIR>/scripts/circleci.py <subcommand> <input> [flags...]
```

`<SKILL_DIR>` は本 SKILL.md が置かれているディレクトリを指すプレースホルダ。呼び出し側は実行時に絶対パスへ置換すること（シェル変数として扱わない）。

### Recommended invocation pattern

permission 管理をシンプルに保つため、以下の呼び出し方を推奨する:

- 1 つの Bash 呼び出しでは 1 つのコマンドだけを実行する（`&&` / `;` / 改行で複数コマンドを連結しない）
- `DIR=$(...)` のようなシェル置換で値を引き回さず、スクリプトが stdout に出すパスを呼び出し側で読み取り、次の Bash 呼び出しに**リテラル引数**として埋め込む

### Input formats

URL を受け付けるサブコマンド (`jobs` / `artifacts` / `steps` / `tests`) は、以下の 3 形式を共通で受け付ける。`pipelines` は URL 入力に対応せず、`--branch --project` のみ。

| 形式 | 例 |
|---|---|
| ジョブ URL | `https://app.circleci.com/pipelines/github/<org>/<project>/<pipeline_num>/workflows/<workflow_id>/jobs/<build_num>` |
| パイプライン URL | `https://app.circleci.com/pipelines/github/<org>/<project>/<pipeline_num>` |
| ブランチ + ジョブ名 | `--branch <name> --project <vcs_short>/<org>/<project> --job <job_name>` |

- ブランチ + ジョブ名形式では「そのブランチの最新パイプライン」「最初に該当ジョブ名を含む workflow」が自動選択される。選定理由（pipeline 番号 / workflow 名 / job_number）が stderr に `Resolved: ...` として出力される
- `<vcs_short>` は `gh`（GitHub）または `bb`（Bitbucket）。`github` / `bitbucket` も受理される
- `--project` の値（`gh/<org>/<project>`）は Claude が `git remote -v` などから補って渡すこと（Skill 内では推測しない）

### Subcommands

| subcommand | 出力 | 必要な input |
|---|---|---|
| `jobs`      | ワークフロー内ジョブ一覧 JSON をインライン出力 (status / started_at / stopped_at / job_number / name 等を含む)。**単一ジョブの状態確認もこれで行う**。出力トップレベルは入力形式により 2 形式に分岐 (下記「`jobs` の出力スキーマ」参照) | URL 入力 3 形式すべて |
| `pipelines` | ブランチ上の pipeline 一覧 (新しい順) を JSON でインライン出力。各 pipeline に `pipelineURL` と配下 workflow の生配列を含める。1ページのみ取得し、続きは `--page-token` で辿る。**用途**: 最新ではない過去 run を調査する / 同じブランチで並走している複数 pipeline から目的の pipelineURL を選ぶ。最新 run でいいなら他のサブコマンドが `--branch --project --job` で自動解決するのでこれは不要 | `--branch --project` のみ (URL 入力非対応) |
| `artifacts` | artifact 一覧 (path, url, node_index) をインライン出力 (next_page_token を辿って全件) | ジョブ URL or ブランチ+ジョブ名 |
| `steps`     | step メタ (resource_class / parallelism / 各 step・action の status / 所要時間) と 各 action の生 stdout/stderr をディレクトリ (`circleci-steps-...`) に保存し、絶対パスを stdout に出力。`--output-dir DIR` で保存先指定。**1 度の API コールで「リソース使用量の調査」と「ログの読解」の両方をカバー** (※ 実 CPU/メモリ使用率は CircleCI 公式 API では取得不可)。`--logs` (all/failed/none) と `--logs-match REGEX` で取得するログを絞れる (下記「`steps` のログ絞り込み」参照) | ジョブ URL or ブランチ+ジョブ名 |
| `tests`     | テスト結果全件 (next_page_token を辿る) を 1 ファイル (`circleci-tests-...json`) に保存し、絶対パスを stdout に出力。`--output-dir DIR` で保存先指定。フィルタは無し — 読み取り側で `jq` する | ジョブ URL or ブランチ+ジョブ名 |

### `jobs` の出力スキーマ

入力形式によってトップレベル構造が異なる。jq を書く前に必ずこちらを確認すること。

- **ジョブ URL / `--branch --project --job`**: 単一 workflow の job 一覧
  ```
  {"items": [<job, ...>], "next_page_token": null}
  ```
  抽出例: `jq '.items[] | {name, status}'`

- **パイプライン URL**: workflow ごとに集約
  ```
  {
    "pipeline_number": 12345,
    "pipeline_id": "...",
    "workflows": [
      {"id": "...", "name": "<workflow_name>", "jobs": [<job, ...>]}
    ]
  }
  ```
  抽出例: `jq '.workflows[] | {wf: .name, jobs: [.jobs[] | {name, status}]}'`

各 `<job>` には `name` / `status` / `job_number` / `started_at` / `stopped_at` 等が含まれる。

### ファイル/ディレクトリ出力 (steps / tests)

#### 共通

- 保存先は `--output-dir` が無ければ `$PWD` 直下
- パーミッションは ファイル 0600 / ディレクトリ 0700 (CI ログには env 由来の secret が混じることがあるため)
- ユーザーの一時ファイル配置方針があれば、それに従って `--output-dir` を明示的に指定すること

#### `steps` の出力 (ディレクトリ)

- ディレクトリ名: `circleci-steps-<org>-<project>-<job_name>-<build_num>/`
- **既存ディレクトリがあるとエラー終了**する (古い run と混ざらないようにするため)。再取得したいときは事前に削除する
- 構成:
  - `meta.json` — job 全体のメタ + `steps[].actions[]` 配列 (各 action に `log_path` = 対応するログファイル名 or null、`log_status` = ログ取得結果。下記「`steps` のログ絞り込み」参照)
  - `step-NNN-<sanitized name>-<action_index>.log` — 1 action 1 ファイルの生ログ。parallelism > 1 のときは `-0`, `-1`, ... と分かれる
- 解析の典型フロー: まず `meta.json` を Read してどの step を見るか決める → 該当する `.log` だけ Read する (大きなジョブで巨大ログを全件 Read しなくて済む)
- jq 例:
  - 失敗 step 抽出: `jq '.steps[] | select(.actions[].status == "failed")' <dir>/meta.json`
  - 遅い step トップ 5: `jq '[.steps[] | {name, ms: ([.actions[].run_time_millis] | add)}] | sort_by(-.ms) | .[0:5]' <dir>/meta.json`
  - 失敗 action のログパス一覧: `jq -r '.steps[].actions[] | select(.status == "failed") | .log_path' <dir>/meta.json`
  - 絞り込みで未取得の action 一覧: `jq -r '.steps[].actions[] | select(.log_status == "skipped")' <dir>/meta.json`

#### `steps` のログ絞り込み (`--logs` / `--logs-match`)

step/action 数が多いジョブで全 action のログを S3 から逐次取得すると遅い。見たいログだけに絞ると取得回数が減り高速化できる。デフォルト (`--logs all`・`--logs-match` 無し) は従来どおり全件取得。

- `--logs all` (既定): 全 action のログを取得
- `--logs failed`: status が失敗 (`failed` / `timedout` / `infrastructure_fail` / `canceled`) の action のみ取得
- `--logs none`: ログを取得せず `meta.json` だけ生成
- `--logs-match REGEX`: step 名に正規表現 (`re.search` の部分一致) がマッチする step のみ取得。完全一致は `^...$` を書く。`--logs failed` と併用すると AND (失敗 かつ 名前マッチ)
- `--logs none` と `--logs-match` の併用、不正な正規表現はエラー終了する

各 action の `log_status` (meta.json) で取得結果を判別できる:

- `saved`: 取得・保存済み (`log_path` に実ファイル名)
- `skipped`: 絞り込みで意図的に未取得 (`log_path` は null)
- `no_output`: presigned URL が無く取得不能 (`log_path` は null)
- `fetch_failed`: 取得を試みたが失敗 (`log_path` は null)

2 段階の使い方: まず `--logs none` で `meta.json` だけ取得して step 構成を把握し、見たい step 名を決めてから別 run で `--logs-match '<step名>'` を取得する (毎回 fresh なディレクトリを作るため、`--output-dir` を変えるか既存を削除する)。

#### `tests` の出力 (ファイル)

- ファイル名: `circleci-tests-<org>-<project>-<job_name>-<build_num>.json`
- 保存後は `jq` で抽出する
  - 失敗テスト抽出例: `jq '.items[] | select(.result == "failure")' <path>`
  - 結果別カウント例: `jq '[.items[].result] | group_by(.) | map({result: .[0], count: length})' <path>`

## Examples

以下の例では、組織・プロジェクト・ブランチ・ジョブ名はダミー値 (`myorg/myproject` / `main` / `build` / `test` / `lint`)。実際には対象に合わせて差し替える。

### `jobs`

ジョブ URL から状態確認（jobs の出力から該当ジョブを抽出）。jq への受け渡しはパイプ 1 段なので 1 Bash 呼び出しで OK:

```bash
<SKILL_DIR>/scripts/circleci.py jobs \
  'https://app.circleci.com/pipelines/github/myorg/myproject/12345/workflows/abcdef01-2345-6789-abcd-ef0123456789/jobs/9876' \
  | jq '.items[] | select(.job_number == 9876)'
```

パイプライン URL から workflow ごとの全ジョブ一覧（出力は workflows 配列）:

```bash
<SKILL_DIR>/scripts/circleci.py jobs \
  'https://app.circleci.com/pipelines/github/myorg/myproject/12345' \
  | jq '.workflows[] | {wf: .name, jobs: [.jobs[] | {name, status}]}'
```

### `steps`

ジョブ URL から step メタ + 全 step の生ログを保存:

```bash
<SKILL_DIR>/scripts/circleci.py steps \
  'https://app.circleci.com/pipelines/github/myorg/myproject/12345/workflows/abcdef01-2345-6789-abcd-ef0123456789/jobs/9876' \
  --output-dir ./tmp
# stdout: <DIR> = ./tmp/circleci-steps-myorg-myproject-build-9876
```

stdout から得た `<DIR>` をリテラルに埋め込んで、次の Bash 呼び出しで jq する（失敗 step 抽出例）:

```bash
jq '.steps[] | select(.actions[].status == "failed")' <DIR>/meta.json
```

遅い step トップ 5 を見たいときも同様に 2 段階。まず steps を保存:

```bash
<SKILL_DIR>/scripts/circleci.py steps \
  --branch main --project gh/myorg/myproject --job build \
  --output-dir ./tmp
```

stdout の `<DIR>` を埋め込んで:

```bash
jq '[.steps[] | {name, ms: ([.actions[].run_time_millis] | add)}] | sort_by(-.ms) | .[0:5]' <DIR>/meta.json
```

リソース使用量だけが知りたい場合も `steps` の `meta.json` から拾える:

```bash
jq '{parallelism, executor, resource_class, build_time_millis}' <DIR>/meta.json
```

step/action 数が多いジョブでログ取得を絞る例。失敗 step のログだけ取得:

```bash
<SKILL_DIR>/scripts/circleci.py steps \
  --branch main --project gh/myorg/myproject --job build \
  --logs failed --output-dir ./tmp
```

まず meta だけ取得して step 構成を把握する (ログ DL なし):

```bash
<SKILL_DIR>/scripts/circleci.py steps \
  --branch main --project gh/myorg/myproject --job build \
  --logs none --output-dir ./tmp
```

step 名を確認してから、特定 step のログだけ取得する (例: 名前に "go build" を含む step):

```bash
<SKILL_DIR>/scripts/circleci.py steps \
  --branch main --project gh/myorg/myproject --job build \
  --logs-match 'go build' --output-dir ./tmp
```

### `tests`

失敗テスト一覧（まず保存、次に jq で抽出）:

```bash
<SKILL_DIR>/scripts/circleci.py tests \
  --branch main --project gh/myorg/myproject --job test \
  --output-dir ./tmp
# stdout: <TESTS_FILE> = ./tmp/circleci-tests-myorg-myproject-test-<build>.json
```

```bash
jq '.items[] | select(.result == "failure")' <TESTS_FILE>
```

### `pipelines`

ブランチの pipeline 一覧（新しい順、各 pipeline に配下 workflow を含む）:

```bash
<SKILL_DIR>/scripts/circleci.py pipelines \
  --branch main --project gh/myorg/myproject
```

pipelines の出力から pipelineURL を取り出して jobs サブコマンドに繋ぐ場合は、まず jq で URL を抽出:

```bash
<SKILL_DIR>/scripts/circleci.py pipelines \
  --branch main --project gh/myorg/myproject \
  | jq -r '.items[0].pipelineURL'
# stdout: <PIPELINE_URL>
```

stdout の URL をリテラルで次の呼び出しに渡す:

```bash
<SKILL_DIR>/scripts/circleci.py jobs '<PIPELINE_URL>'
```

pipelines の続きを取得（next_page_token を渡す）:

```bash
<SKILL_DIR>/scripts/circleci.py pipelines \
  --branch main --project gh/myorg/myproject \
  --page-token '<next_page_token>'
```

## トラブルシューティング

- `Error: CIRCLECI_TOKEN is not set ...` → CircleCI Personal API Token を `https://circleci.com/settings/user/tokens` で発行し、シェルの rc ファイル等に `export CIRCLECI_TOKEN=...` を追記して新規シェルで有効化する。既存 Claude Code セッションには反映されないので、有効化後に Claude Code を再起動
- `Error: CircleCI API v2 returned HTTP 404 ...` → 入力 URL のジョブ番号が違う、もしくはトークン保有者にアクセス権がない
- `Error: No pipeline found for branch '...' in <slug>` → ブランチ名のタイポ or プロジェクトが間違っている可能性
- `Error: Job '<name>' not found in any workflow of the latest pipeline ...` → ジョブ名のタイポ、または対象 run でそのジョブが skip された可能性
- `Error: URL input and --branch/--project/--job are mutually exclusive` → URL 指定とフラグ指定は併用不可
- `Error: Output directory already exists: ...` → `steps` の出力先ディレクトリが既存。古い snapshot を削除してから再実行
