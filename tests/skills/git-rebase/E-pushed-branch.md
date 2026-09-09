# E: push 済みブランチの整理（force push 確認）

## ターゲット skill

`skills/git-rebase/SKILL.md`

## シナリオ背景

既に origin に push 済みの feature branch で commit を整理する。書き換え対象が `@{u}` の祖先に含まれるため force push が必要。skill は Y/N 確認を取り、最終出力に `git push --force-with-lease` を案内するが、**push 自体は実行しない**。

## セットアップ

```bash
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git-rebase-test-E.XXXXXX")
cd "$TEST_DIR"

git init -q -b main --bare origin.git
git clone -q origin.git work
cd work
git config user.email "test@example.com"
git config user.name "Test User"
git config commit.gpgsign false
git config tag.gpgsign false

echo "main v1" > main.txt
git add main.txt
git commit -q -m "Initial commit"
git push -q origin main

git checkout -q -b feature
echo "feature work" > feature.txt
git add feature.txt
git commit -q -m "Add feature"

echo "feature v2" >> feature.txt
git add feature.txt
git commit -q -m "Fix typo"

# upstream 設定 + push
git push -q -u origin feature

echo "TEST_DIR=$TEST_DIR"
echo "WORK_DIR=$TEST_DIR/work"
```

セットアップ後の状態：

- `feature` branch は origin に push 済み、upstream 設定済み（`@{u}` = `origin/feature`）
- 直近 2 commit が squash 対象（`Add feature` + `Fix typo`）
- 書き換え対象 sha のうち最古のものは `@{u}` の祖先に含まれる → force push 必須

## ユーザー指示

> 直近 2 commit を 1 つに squash して。message は最初のを使って。

## 要件チェックリスト

1. `[critical]` rebase 後の `feature` branch の commit 数（main からの差分）が `1`（squash 完了）
2. `[critical]` HEAD の commit subject が `Add feature`（最初の commit の message が採用された）
3. `[critical]` `git rev-parse HEAD` が `git rev-parse @{u}` と一致しない（force push が必要な分岐状態）
4. `[critical]` `origin/feature` の sha がセットアップ直後と同じ（**skill が push を実行していない**）
5. `git rev-parse @{u}` で upstream を取得し、`git merge-base --is-ancestor <oldest_rewritten_sha> @{u}` で push 済み判定を実施している
6. 「push 済みなので force push が必要です。続行しますか？」相当の Y/N 確認を取っている
7. ユーザー承認後に rebase を実行している
8. 最終出力に `git push --force-with-lease` のコマンドを添えている
9. 最終サマリーが「形式 A」で、`### 次のアクション` に force-with-lease を含む
