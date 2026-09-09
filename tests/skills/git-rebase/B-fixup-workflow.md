# B: fixup workflow（既存 commit に修正差分を取り込む）

## ターゲット skill

`skills/git-rebase/SKILL.md`

## シナリオ背景

過去の commit にバグ修正を統合したい。作業ツリーに修正差分を入れた状態で、対象 commit を指定して `git commit --fixup` → `--autosquash` の workflow を回すパターン（中央値ケース：fixup workflow の典型）。

## セットアップ

以下を実行して fixture を作る。

```bash
TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/git-rebase-test-B.XXXXXX")
cd "$TEST_DIR"
git init -q -b main
git config user.email "test@example.com"
git config user.name "Test User"
git config commit.gpgsign false
git config tag.gpgsign false

echo "main feature" > main.txt
git add main.txt
git commit -q -m "Add main feature"

cat > helper.txt <<'EOF'
helper v1
EOF
git add helper.txt
git commit -q -m "Add helper"

echo "doc" > README.md
git add README.md
git commit -q -m "Add README"

# 修正差分: helper.txt のバグを直したい状態（dirty）
cat > helper.txt <<'EOF'
helper v1 fixed
EOF

echo "TEST_DIR=$TEST_DIR"
```

セットアップ後の状態：

- 3 commit（HEAD = "Add README" → "Add helper" → "Add main feature"）
- 作業ツリーに helper.txt の未 stage 差分あり（**dirty**）
- upstream 未設定

## ユーザー指示

> 'Add helper' の commit に helper.txt の修正を fixup として取り込んで。

## 要件チェックリスト

1. `[critical]` `git rev-list --count HEAD` が `3`（fixup されたので commit 数は増えていない）
2. `[critical]` `git log --format=%s` の subject 順序が `Add README` → `Add helper` → `Add main feature`（順序維持）
3. `[critical]` `git show HEAD~1:helper.txt` の出力が `helper v1 fixed`（fixup が "Add helper" commit に統合されている。順序維持を要件 2 で担保しているので `HEAD~1` が "Add helper" になる）
4. `[critical]` 作業ツリーが clean（`git status --porcelain` が空）
5. fixup 対象の path をユーザーに確認してから `git add` を実行している（部分 staging を勝手に壊さない）
6. `git commit --fixup=<target_sha>` を実行している
7. `git rebase -i --autosquash <BASE_ARG>` を実行している（autosquash を付けて rebase）
8. dirty を許容している（commit / stash を促していない）
9. 最終サマリーが「形式 B（1 commit ピンポイント型）」で出ている
