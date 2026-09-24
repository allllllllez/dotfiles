---
paths: "**/*.tf"
---

# Terraform Coding Rules

## Code Formatting

- `terraform fmt -recursive` でフォーマット統一すること

### ブロック内の並び順

1. meta-arguments（`count`, `for_each`, `provider`, `depends_on`）
2. 引数（arguments）
3. ネストブロック（blocks）
4. `lifecycle` ブロック（最後）

各グループ間は空行1行で区切る。

```hcl
resource "aws_instance" "example" {
  count = 3

  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  root_block_device {
    volume_size = 20
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

## Naming Conventions

- **snake_case**（小文字 + アンダースコア）を使用
- リソース名はリソースタイプ名を含めない名詞・単数形にする
- 単一リソースの場合は `main` と命名する
- 作成されるリソースの `name` 属性にはハイフン `-` を使用

```hcl
# BAD
resource "aws_instance" "webAPI-aws-instance" {}
resource "aws_instance" "web_apis" {}

# GOOD
resource "aws_instance" "web_api" {}
resource "aws_vpc" "main" {}
```

## File Organization

| ファイル | 役割 |
|----------|------|
| `terraform.tf` | Terraform・provider のバージョン制約 |
| `providers.tf` | provider 設定 |
| `main.tf` | リソース・data source |
| `variables.tf` | variable 宣言（アルファベット順） |
| `outputs.tf` | output 宣言（アルファベット順） |
| `locals.tf` | local values |

## Version Pinning

Terraform・provider・module のバージョンは必ず固定する。

```hcl
terraform {
  required_version = ">= 1.7"

  required_providers {
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "~> 1.0"
    }
  }
}
```

- `~> 1.0` : マイナーバージョンの更新のみ許可
- `>= 1.0, < 2.0` : 範囲指定

### メジャーバージョンを上げるとき

自分の判断でterraform/terragrunt等のメジャーバージョンを上げた場合、
使い始める前に公式の移行ガイド・breaking changesを一度通しで読む。
個別のエラーが出るたびに1つずつ対症療法で直さない
（例: CLIサブコマンドの廃止、フラグの扱いの変更、対話プロンプトの追加は
同じ移行で同時に起きることが多い）。

## Dynamic Resource Creation

- 名前付きインスタンスには `count` より `for_each` を優先
- `count` は条件分岐（0 or 1）に使用

```hcl
# for_each: 名前付きリソース
resource "aws_instance" "web" {
  for_each = var.instance_names
  tags     = { Name = each.key }
}

# count: 条件分岐
resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.enable_monitoring ? 1 : 0
}
```

## Investigation Sources (調査時の優先参照先)

Terraform関連の調査を行う際は、以下の順序で優先的に参照すること。

1. **Terraform公式ドキュメント**: https://developer.hashicorp.com/terraform
2. **Terraform Registry (snowflakedb)**: https://registry.terraform.io/providers/snowflakedb/snowflake/1.0.1
3. **GitHub リポジトリ**:
   - Snowflake provider: `snowflakedb/terraform-provider-snowflake`
   - Terraform本体: `hashicorp/terraform`

**注意**: 旧リポジトリ `Snowflake-Labs/terraform-provider-snowflake` は参照しないこと。現在のproviderは `snowflakedb` 名前空間に移行済み。

### 断定して書く前に確認する対象

- provider の認証設定（環境変数名、引数名）は「見慣れているから」で断定しない。
  provider のメジャーバージョンが変わっていれば慣習ごと変わる。
  新規リソースと同様に、書く前に公式ドキュメントを1回fetchする。
- 非決定的関数（`GET_PRESIGNED_URL`、`CURRENT_TIMESTAMP` 等）を含むクエリを
  Dynamic Table・Materialized View・Cortex Search Service など
  インクリメンタル更新系オブジェクトのソースとして設計に組み込む前に、
  対応可否を確認する。「宣言的で綺麗」だけを理由に推奨しない。

## Validation Tools

コミット前に必ず実行:

```bash
terraform fmt -recursive
terraform validate
```

推奨ツール:
- `tflint` - Linting
- `checkov` / `tfsec` - セキュリティスキャン

## Credentials and Identities

Terraform リソース定義において、環境固有の値・外部接続先情報を直書きしてはならない。
必ず `variable` または `locals` に外だしすること。

### 直書き禁止の対象

- アカウント識別子（Snowflake Account Identifier 等）
- ホスト名・接続先エンドポイント
- Subscription ID / リソースID
- IPアドレス（`locals` で管理する場合を除く）
- 認証情報・シークレット（これは当然）

### 正しいパターン

```hcl
# BAD: 直書き
resource "snowflake_database" "db" {
  replication {
    enable_to_account {
      account_identifier = "XY0123456789.ZW01234"  # 直書き禁止
    }
  }
}

# GOOD: variable に外だし
resource "snowflake_database" "db" {
  replication {
    enable_to_account {
      account_identifier = var.replication_target_account_identifier
    }
  }
}
```

### variable 定義のルール

- type と description を必ず記載する
- description には用途・形式・取得元を明記する
- 秘匿情報には sensitive = true を付与する

### locals vs variable の使い分け

| 用途 | 使用すべき定義 |
|------|----------------|
| 環境固有・外部接続先情報 | variable（HCP Terraform管理） |
| プロジェクト内の定数・命名規則 | locals |
| IP アドレスリスト（内部管理） | locals |
| 他リソースからの参照値 | リソース属性の直接参照 |

