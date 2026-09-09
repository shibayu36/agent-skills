# A: 直近 3 commit を squash（最初の commit の message を採用）

## ターゲット skill

`skills/git-rebase/SKILL.md`

## シナリオ背景

ローカル開発中に「typo fix」「minor refactor」と細かい commit を連ねてしまった。push 前に 1 つの commit に統合し、message は最初の commit のものを採用したい（中央値ケース：最も頻繁に使う commit 整理パターン）。

## セットアップ

以下を実行して fixture を作る。

```bash
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git-rebase-test-A.XXXXXX")
cd "$TEST_DIR"
git init -q -b main
git config user.email "test@example.com"
git config user.name "Test User"
git config commit.gpgsign false
git config tag.gpgsign false

echo "line1" > file.txt
git add file.txt
git commit -q -m "Add initial feature"

echo "line2" >> file.txt
git add file.txt
git commit -q -m "typo fix"

echo "line3" >> file.txt
git add file.txt
git commit -q -m "minor refactor"

echo "TEST_DIR=$TEST_DIR"
```

セットアップ後の状態：

- 3 commit が linear に並んでいる（HEAD = "minor refactor"）
- upstream 未設定（= push 済みではない）
- 作業ツリー clean

セットアップ直後の HEAD tree を後で比較するため `git rev-parse HEAD^{tree}` の値を記録しておくと検証しやすい。

## ユーザー指示

subagent には以下の自然文を与える：

> 直近 3 commit を 1 つに squash して。message は最初のを使って。

## 要件チェックリスト

`[critical]` は最終 git 状態の不変条件。それ以外は skill のプロセス遵守を見る normal 項目。

1. `[critical]` `git rev-list --count HEAD` が `1`（commit が 1 つに集約されている）
2. `[critical]` `git log -1 --format=%s` が `Add initial feature`（最初の commit の subject が採用されている）
3. `[critical]` `git rev-parse HEAD^{tree}` が setup 直後の HEAD tree と一致（squash したのみで内容変化がない）
4. rebase 実行前に todo 案（`pick / squash / squash` 相当）をユーザーに提示している
5. dirty 判定を実施している（`git status --porcelain` の実行痕跡がある）
6. push 済み判定を実施している。upstream 未設定で「push 済みではない」と判断した記述があれば可
7. 最終サマリーが「形式 A（範囲全体型）」で出ている（`### 結果（rebase 後の commit log）` と `### 変更内容` を含む）
8. `rebase -i` の todo 差し替えに `GIT_SEQUENCE_EDITOR` を、message 差し替えに `GIT_EDITOR` を併用している（実行コマンド痕跡）
