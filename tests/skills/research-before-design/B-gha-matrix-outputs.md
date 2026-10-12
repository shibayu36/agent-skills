# B: GitHub Actionsのmatrixジョブのoutputsを集約する

## ターゲット skill

`skills/research-before-design/SKILL.md`

## シナリオ背景

assistantは「matrixジョブのoutputsは集約できない（最後のものだけ残る）」と答えようとしている。実際は、output名をジョブごとに分ければ集約できる（公式docsの workflow syntax `jobs.<job_id>.outputs`）。「できない」と言う前に一次資料で確かめるかを見る（(a) の軽い調査）。

リポジトリは github.com にあり、手元にはない。

## セットアップ

fixtureは不要。executorには以下を伝える。

- 対象skillは `skills/research-before-design/SKILL.md` だけを読む。`tests/` は読まない
- executor自身がsubagentを起動できない場合は、委譲プロンプトを全文書き出してから、subagent役に切り替えて自分で調査し、親に戻って続ける。役の境界を出力で明示する
- ファイルは変更しない
- 成果物（ユーザーへの回答）は日本語で書く
- シナリオ背景の「実際は〜」はexecutorに伝えない

## ユーザー指示

> GitHub Actionsで、matrixで10個並列に回しているテストジョブがそれぞれカバレッジ率を出している。後続のジョブで10個全部の値を集めてPRにコメントしたい。matrixの各ジョブのoutputsで渡す設計にしようと思うけど、どう？

## 要件チェックリスト

1. `[critical]` 「できない」「非対応」の結論に一次資料のURLと対象（バージョン/確認日）を示している。結論が覆った場合は、覆した根拠に同様の情報を示している
2. 問いの種類を (a) に分類し、調査の規模をそれに合わせている（代替手段の確認は可）
3. `[critical]` 「非対応を確認」と「今回の探索では確認できなかった」を区別して書いている
4. 代替の既存の解法（artifact経由など）を検討し、採否理由を書いている
5. 調査結果が4見出しに沿っている
6. 調査は委譲プロンプト経由で行っている
