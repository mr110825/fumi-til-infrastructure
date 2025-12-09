# fumi-til-infrastructure

技術ブログ [fumi-til.com](https://fumi-til.com) のAWSインフラをTerraformで管理するリポジトリ。

---

## このプロジェクトで得たスキル

- **インフラ設計**: S3 + CloudFrontによる静的サイト構成（Lightsailと比較検討し、コスト・運用面で最適な構成を選択）
- **IaC**: Terraform module設計（将来のテスト実装・拡張を見据えた構成）、movedブロックによる安全なリファクタリング
- **CI/CD**: GitHub Actions + OIDC認証（アクセスキー不使用）
- **セキュリティ**: OAC（AWS推奨の新方式）、sensitive変数による機密情報管理
- **運用設計**: CloudWatch監視、Athenaによるログ分析（人気記事・アクセス傾向の把握）
- **トラブルシューティング**: CloudFront 404エラーの原因特定と解決

---

## アーキテクチャ

![アーキテクチャ図](docs/S3+CloudFront構成図.drawio.svg)

| 項目 | 内容 |
|------|------|
| ホスティング | S3 + CloudFront（サーバーレス） |
| DNS/証明書 | Route53 + ACM |
| CI/CD | GitHub Actions（OIDC認証） |
| 監視 | CloudWatch + SNS |
| IaC | Terraform（8 modules） |
| 月額コスト | 約100〜150円 |

---

## 技術的なこだわり

### 1. OAC vs OAI：なぜ新方式を選んだか

S3へのアクセス制御として、旧方式のOAIではなくOAC（2022年登場）を採用。

| 判断基準 | OAI（旧） | OAC（採用） |
|----------|----------|-------------|
| AWS推奨 | 非推奨 | 推奨 |
| SSE-KMS対応 | ❌ | ✅ |
| POST/PUT対応 | ❌ | ✅ |

**判断理由**: 新規構築で非推奨技術を選ぶ理由がない。将来的なKMS暗号化対応も見据えて選択。

---

### 2. OIDC認証：なぜアクセスキーを使わないか

GitHub ActionsからAWSへの認証にOIDCを採用。

| 比較項目 | アクセスキー | OIDC（採用） |
|----------|-------------|--------------|
| 漏洩リスク | 高（永続的） | 低（15分で期限切れ） |
| ローテーション | 手動管理必要 | 不要 |
| ブランチ制限 | 不可 | IAM条件で制御可能 |

**判断理由**: AWS/GitHub公式推奨。アクセスキーは漏洩リスクと管理の手間が大きいため、OIDCを採用。

---

### 3. movedブロック：既存リソースを壊さずにmodule化

`moved`ブロックを使用し、本番稼働中のリソースをダウンタイムなしでmodule化。

```hcl
moved {
  from = aws_s3_bucket.content
  to   = module.s3_content.aws_s3_bucket.this
}
```

**結果**: `Plan: 0 to add, 0 to change, 0 to destroy`（リソース再作成なし）

**判断理由**: 個人開発ではmodule化は必須ではないが、将来のテスト実装・拡張を見据えて採用。実務で一般的な設計パターンを経験しておきたかった。

---

### 4. CloudFront 404エラーの解決

**問題**: GitHub Pagesでは正常だったブログが、CloudFront移行後に404エラー。

**原因特定**:
- GitHub PagesとCloudFrontの動作を比較
- OAC使用時はS3の静的ウェブサイトホスティング機能が使えず、`/posts/article/` → `/posts/article/index.html` の自動補完が効かないことを発見

**解決**: CloudFront FunctionでURLリライトを実装。

---

## 監視・アラート設計

| アラーム | 閾値 | 設定理由 |
|----------|------|----------|
| 5xxエラー率 | 1% | サーバーエラーは重大、低閾値で早期検知 |
| 4xxエラー率 | 5% | 404等は一定量発生、緩めに設定 |

**誤検知防止の工夫**:
- `evaluation_periods: 2`（2回連続で超過時のみアラート）
- `treat_missing_data: notBreaching`（低トラフィック時の誤検知防止）

---

## ディレクトリ構成

```
fumi-til-infrastructure/
├── README.md
├── docs/
│   └── architecture.svg
├── backend-setup/          # tfstate用（初回のみ）
├── environments/
│   └── prod/               # 本番環境
└── modules/                # 再利用可能な8モジュール
    ├── s3-content/
    ├── s3-logs/
    ├── cloudfront/
    ├── route53/
    ├── acm/
    ├── sns/
    ├── iam-github-actions/
    └── cloudwatch/
```

<details>
<summary>モジュール詳細</summary>

| Module | 主な責務 |
|--------|----------|
| s3-content | コンテンツ保存、暗号化、パブリックアクセスブロック |
| s3-logs | ログ保存、90日ライフサイクル |
| cloudfront | CDN、OAC、URLリライトFunction |
| route53 | Aliasレコード |
| acm | 証明書参照（data source） |
| sns | アラート通知 |
| iam-github-actions | OIDC認証、最小権限ポリシー |
| cloudwatch | ダッシュボード、アラーム |

</details>

---

## セットアップ手順

<details>
<summary>手順を表示</summary>

### 前提条件
- AWS CLI設定済み
- Terraform >= 1.0.0
- Route53でドメイン取得済み
- ACM証明書発行済み（us-east-1）

### 1. tfstate用バックエンドの作成
```bash
cd backend-setup
terraform init && terraform apply
```

### 2. 本番環境のデプロイ
```bash
cd environments/prod
echo 'alert_email = "your-email@example.com"' > terraform.tfvars
terraform init && terraform apply
```

</details>

---

## 技術スタック

| カテゴリ | 技術 |
|----------|------|
| IaC | Terraform >= 1.0.0 |
| CI/CD | GitHub Actions |
| AWS | S3, CloudFront, Route53, ACM, CloudWatch, SNS, Athena, IAM |
| 静的サイト | Hugo + Blowfish |

---

## 参考資料

- [CloudFront + S3 OAC設定](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/private-content-restricting-access-to-s3.html)
- [GitHub Actions OIDC + AWS](https://docs.github.com/ja/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services)
- [Terraform movedブロック](https://developer.hashicorp.com/terraform/language/modules/develop/refactoring)
- [CloudFront Functions](https://docs.aws.amazon.com/ja_jp/AmazonCloudFront/latest/DeveloperGuide/cloudfront-functions.html)
