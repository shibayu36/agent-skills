# D: Go 1.21のプロジェクトでrange-over-funcのイテレータを使う

## ターゲット skill

`skills/research-before-design/SKILL.md`

## シナリオ背景

ユーザーは `iter.Seq2` を返す設計を提案しているが、プロジェクトの go.mod は `go 1.21` で、range-over-func は Go 1.23 から。前提をプロジェクトのファイルで確かめるかを見る。

手元のtoolchainが1.23以上だと、`go version` を見て「使える」と誤判定しやすい。それを引っかけにしている。

## セットアップ

```bash
bash tests/skills/research-before-design/fixtures/setup-D.sh
```

出力された `TEST_DIR` をプロジェクトのルートとして扱う。

セットアップ後の状態：

- `go.mod`: `module example.com/usersvc` / `go 1.21` / `require github.com/jackc/pgx/v5 v5.5.0`
- `main.go`: `User` 型と `ListUsersPage(afterID int64, limit int) ([]User, error)`、それを呼ぶ `main`

executorには以下を伝える。

- 対象skillは `skills/research-before-design/SKILL.md` だけを読む。`tests/` は読まない
- executor自身がsubagentを起動できない場合は、委譲プロンプトを全文書き出してから、subagent役に切り替えて自分で調査し、親に戻って続ける。役の境界を出力で明示する
- ファイルは変更しない
- 成果物（ユーザーへの回答）は日本語で書く

## ユーザー指示

> ユーザー一覧をページングしながら全件取得する処理を作りたい。range-over-funcのイテレータ（iter.Seq2[User, error]）で返す設計にしようと思うけど、どう？設計案を出して。

## 要件チェックリスト

1. `[critical]` プロジェクトのGoバージョンを go.mod から確認し、その値を明示している
2. `[critical]` range-over-func / iter が使えるようになったGoのバージョン（1.23）を一次資料で示し、このプロジェクトでそのまま使えないと結論している
3. 手元の `go version` と go.mod の言語バージョンを混同していない
4. 対応策（goディレクティブを上げる場合の影響、上げない場合の代替設計）を提示している
5. 問いの種類を分類し、調査の規模をそれに合わせている
