# C: origin/main 取り込み（conflict なし）

## ターゲット skill

`skills/git-rebase/SKILL.md`

## シナリオ背景

ローカル feature branch に最新の `origin/main` を取り込みたい。conflict は起きない単純な fast-rebase（中央値ケース：upstream 取り込みの典型）。

## セットアップ

以下を実行して fixture を作る。bare repo を origin に見立て、別 clone から origin/main を進めることでリモート更新を再現する。

```bash
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git-rebase-test-C.XXXXXX")
cd "$TEST_DIR"

# origin (bare) 作成
git init -q -b main --bare origin.git

# ローカル作業 clone
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

# feature branch を作って独自 commit を積む
git checkout -q -b feature
echo "feature work" > feature.txt
git add feature.txt
git commit -q -m "Add feature"
git push -q -u origin feature

# 別 clone から origin/main を進める（リモートが先に進んだ状況）
cd ..
git clone -q origin.git other
cd other
git config user.email "other@example.com"
git config user.name "Other User"
git config commit.gpgsign false
git config tag.gpgsign false
echo "main v2" > another.txt
git add another.txt
git commit -q -m "Add another file on main"
git push -q origin main

# work に戻り、feature checkout 状態にする
cd ../work

echo "TEST_DIR=$TEST_DIR"
echo "WORK_DIR=$TEST_DIR/work"
```

セットアップ後の状態：

- カレントは `work/` で、checkout は `feature` branch
- `origin/main` には未 fetch の新 commit がある（`Add another file on main`）
- feature 自身は独自 commit 1 個（`Add feature`）
- conflict 起こす差分はない（編集ファイルが別）

## ユーザー指示

> origin/main を取り込んで。

## 要件チェックリスト

1. `[critical]` rebase 後の `feature` branch HEAD tree に `another.txt` が含まれる（origin/main の変更が取り込まれた）
2. `[critical]` `feature.txt` も HEAD tree に残っている（feature 独自 commit が消えていない）
3. `[critical]` `git rev-list --count origin/main..HEAD` が `1`（feature 独自 commit は 1 つだけ）
4. `[critical]` `git merge-base --is-ancestor origin/main HEAD` が成功する（origin/main が HEAD の祖先）
5. `git symbolic-ref --short refs/remotes/origin/HEAD` で base を解決している
6. `git fetch origin` を実行している
7. `git rebase origin/main` を実行している（`origin/origin/main` のような二重 prefix になっていない）
8. push 済み判定を実施し、force push 不要（rewrite 対象が `@{u}` の祖先ではない）と判断している、または force push 案内を出している
9. 最終サマリーが「形式 A（範囲全体型）」で出ている
