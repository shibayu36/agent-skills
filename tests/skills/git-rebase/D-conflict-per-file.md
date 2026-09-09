# D: conflict 解消（1 ファイルずつ、複数ファイル衝突）

## ターゲット skill

`skills/git-rebase/SKILL.md`

## シナリオ背景

`origin/main` 取り込み中に **2 ファイル**が同時に conflict する。skill は「両側意図の要約 → 解決案 diff → 承認 → 適用」のループを **1 ファイルずつ** 順番に回し、最後に `--continue` で `GIT_EDITOR` を再付与する必要がある（最重要落とし穴）。

## セットアップ

`config.json` と `README.md` の双方が main / feature の両側で改変されるよう仕込む。

```bash
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git-rebase-test-D.XXXXXX")
cd "$TEST_DIR"

git init -q -b main --bare origin.git
git clone -q origin.git work
cd work
git config user.email "test@example.com"
git config user.name "Test User"
git config commit.gpgsign false
git config tag.gpgsign false

cat > config.json <<'EOF'
{
  "version": "1.0",
  "host": "localhost"
}
EOF
cat > README.md <<'EOF'
# myapp
A demo application.
EOF
git add config.json README.md
git commit -q -m "Initial files"
git push -q origin main

# feature: 両方のファイルを改変
git checkout -q -b feature
cat > config.json <<'EOF'
{
  "version": "1.0",
  "host": "localhost",
  "port": 8080
}
EOF
cat > README.md <<'EOF'
# myapp (with port)
A demo application with port support.

## Usage
Run `myapp --port 8080` to start.
EOF
git add config.json README.md
git commit -q -m "Add port and usage docs"
git push -q -u origin feature

# 別 clone から origin/main を進めて両方を改変（conflict の種を 2 個仕込む）
cd ..
git clone -q origin.git other
cd other
git config user.email "other@example.com"
git config user.name "Other User"
git config commit.gpgsign false
git config tag.gpgsign false
cat > config.json <<'EOF'
{
  "version": "1.1",
  "host": "localhost"
}
EOF
cat > README.md <<'EOF'
# myapp v1.1
A demo application.
EOF
git add config.json README.md
git commit -q -m "Bump version and update title"
git push -q origin main

# work に戻り、feature checkout 状態
cd ../work
git fetch -q origin

echo "TEST_DIR=$TEST_DIR"
echo "WORK_DIR=$TEST_DIR/work"
```

セットアップ後の状態：

- 衝突するファイルは 2 個（`config.json` と `README.md`）
- どちらも feature と origin/main の両側が改変している
- conflict 解消後は両側の意図を統合する必要がある

## ユーザー指示

> origin/main を取り込んで。conflict が出たら 1 ファイルずつ説明して。

## 要件チェックリスト

1. `[critical]` rebase 完了後、`config.json` に `"version": "1.1"` と `"port": 8080` の両方が含まれる
2. `[critical]` rebase 完了後、`README.md` に `v1.1`（main 由来）と `## Usage` セクション（feature 由来）が両方含まれる
3. `[critical]` `host` が `"localhost"` のまま壊れていない（無関係行が破壊されていない）
4. `[critical]` `git rev-list --count origin/main..HEAD` が `1`（feature 独自 commit が 1 つだけ）
5. `[critical]` rebase 完了後、`git status --porcelain` が空（解消漏れがない）
6. conflict ファイルごとに「両側の意図要約 → 解決案 diff → 承認」のループを **2 ファイル分** 回している（`config.json` 解決 → 承認 → `git add` → 次のファイル `README.md` 解決 ... の順序）
7. 1 ファイル目の解決案を提示する時点で 2 ファイル目の解決案を先出ししていない（「まとめて」モードに勝手に切り替えていない）
8. `git rebase --continue` 実行時に `GIT_EDITOR=true`（または `cp` 経由の差し替え）を**再付与**している
9. 最終サマリーが「形式 A（範囲全体型）」で出ている
