# X: stacked rebase で upstream 取り込み + conflict + 全 branch push 済み

## ターゲット skill

`skills/git-rebase/SKILL.md`

## シナリオ背景

stacked branch 構成（`main → feature-base → feature-A → feature-B`）で `origin/main` を取り込む。下位 branch も追従させたい（`--update-refs`）。取り込み中に `feature-base` 層で conflict が発生し、全 branch が push 済みなので各 ref で force push が必要になる。**最も難しい単一シナリオ**：references 読み込み・`--update-refs` 付与・conflict 中の `GIT_EDITOR` 再付与・複数 ref 個別の push 判定がすべて連鎖する。

## セットアップ

スクリプトに分離。実行すると `$TMPDIR/git-rebase-test-X/work` に作業 clone を作り、`feature-B` checkout 状態にする。

```bash
bash tests/skills/git-rebase/fixtures/setup-X.sh
cd "${TMPDIR:-/tmp}/git-rebase-test-X/work"
```

セットアップ後の状態：

- 4 branch（`main` / `feature-base` / `feature-A` / `feature-B`）すべて origin に push 済み
- カレントは `feature-B`
- `origin/main` は `git fetch` 済みで、ローカル未追従の commit `Add name parameter to run()` を持つ
- `feature-base` の commit `Add verbose param to run()` を `origin/main` に rebase 適用しようとすると `app.py` で conflict が発生する仕掛け

セットアップで作られる各 branch の subject（**rebase 後も維持されるべきもの**）：

| branch | subject |
|---|---|
| `feature-base` | `Add verbose param to run()` |
| `feature-A` | `Implement verbose branch` |
| `feature-B` | `Adjust log format` |

## ユーザー指示

> feature-B チェックアウト状態。stacked 構成なので下位 branch も追従させた上で、origin/main を取り込んで。

## 要件チェックリスト

`[critical]` は最終 git 状態（rebase 後の各 branch の sha・関係・内容）。

### 各 branch の subject 維持

1. `[critical]` `git log -1 feature-base --format=%s` が `Add verbose param to run()`
2. `[critical]` `git log -1 feature-A --format=%s` が `Implement verbose branch`
3. `[critical]` `git log -1 feature-B --format=%s` が `Adjust log format`

### 積み上げ関係の維持

4. `[critical]` `git merge-base --is-ancestor origin/main feature-base` が成功（main 取り込み済み）
5. `[critical]` `git merge-base --is-ancestor feature-base feature-A` が成功（積み上げ維持）
6. `[critical]` `git merge-base --is-ancestor feature-A feature-B` が成功（積み上げ維持）

### conflict 解消結果（feature-B HEAD 内容）

7. `[critical]` `feature-B` の `app.py` に以下すべてが含まれる：
   - `name="world"` または `name=` 付きシグネチャ（origin/main 由来）
   - `if verbose:` ブロック（feature-A 由来）
   - `[INFO]` フォーマット（feature-B 由来）

### プロセス遵守（normal）

8. `references/stacked-update-refs.md` を Read で読み込んでいる
9. `git rebase` に `--update-refs` を付けて実行している
10. conflict 解消後、`git rebase --continue` 実行時に `GIT_EDITOR=true`（または `cp` 経由の差し替え）を**再付与**している
11. 各 ref（`feature-base` / `feature-A` / `feature-B`）ごとに `merge-base --is-ancestor` で push 済み判定を実施している
12. 最終出力に **3 branch すべての** `git push --force-with-lease origin <branch>` を案内している
13. skill 自身は `git push` を実行していない（`origin/feature-base` / `origin/feature-A` / `origin/feature-B` の sha がセットアップ直後と同じ）
14. 最終サマリーが「形式 A + stacked 拡張」（`### 結果` `### 変更内容` に加えて `### 更新された下位 branch` 相当の項目を含む）
