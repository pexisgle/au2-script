# pexisgle-script

AviUtl2 用スクリプトです。Lua の前処理に [aulua](https://github.com/karoterra/aviutl2-aulua)、開発環境とパッケージ化に [aviutl2-cli](https://github.com/sevenc-nanashi/aviutl2-cli) を使います。

## 必要環境

- [mise](https://mise.jdx.dev/)
- Windows の開発者モード（`au2` がシンボリックリンクを使うため）

## セットアップ

```bash
mise trust
mise install
au2 prepare
```

Lua の補完には [lua_aviutl_definitions](https://github.com/karoterra/lua_aviutl_definitions) を submodule として使っています。

```bash
git submodule update --init --recursive
```

## 開発

```bash
# AviUtl2 を起動して成果物を配置する
au2 develop

# aulua だけビルドする
mise run build

# ソース変更を監視してビルドする
mise run watch
```

トラックバーなどの定義は [aulua の UI 記法](https://karoterra.github.io/aviutl2-aulua/build/ui.html) で書いてください。`au2 develop` / `au2 release` 時に `aulua build` が走り、`build/` に `.anm2` が出力されます。

## リリース

GitHub Actions の `Release` ワークフローを手動実行するか、ローカルでは次のようにします。

```bash
au2 release --set-version 0.2.0
```
