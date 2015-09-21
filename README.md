# バージョン

- ホストOS
  - [Mac OS X 10.10.5](https://support.apple.com/kb/DL1832)
- ゲストOS
  - Ubuntu 14.04.3 LTS
  - ただし使うのは [Vagrant用の box](https://atlas.hashicorp.com/ubuntu/boxes/trusty64/versions/20150911.0.0)
- [Vagrant](https://www.vagrantup.com/download-archive/v1.7.4.html)
  - 1.7.4
- [Virtualbox](https://www.virtualbox.org/wiki/Downloads)
  - 5.0.4
- [Rbenv](https://github.com/sstephenson/rbenv)
  - 0.4.0-154-g9e664b5
- [Ruby](https://www.ruby-lang.org/ja/)
  - 2.2.3
- [Rails](http://rubyonrails.org/)
  - 4.2.4

# ファイル構成

```
${HOGE_ROOT}/
    .vagrant
    Vagrantfile
    shared/
        .keep
    scripts/
        etc/
            add_LC_ALL_to_locale.sh
        git/
            install.sh
        mysql/
            install.sh
        rbenv/
            install.sh
            install_bundler.sh
            install_libraries.sh
            install_ruby.sh
```

あと、これとは別に `~/.gitconfig` と `~/.gitignore` が必要

# Vagrantfile の中身

```rb
VAGRANTFILE_API_VERSION = 2
SYNCED_FOLDER_BASE_DIR = "/shared"
SCRIPT_BASE_DIR = "scripts"
RB_VERSION = "2.2.3"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # SSH の設定
  # ポートフォワードの設定を有効にする
  # ホストOS の `ssh-agent` に秘密鍵が登録されていないと意味を成さない。
  # `ssh-add -l` で登録されている秘密鍵を確認
  # `ssh-add ~/.ssh/id_rsa` で秘密鍵を登録
  config.ssh.forward_agent = true

  # 構築に必要なリソース
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
  end

  # NFS 共有を動かすためにプライベートネットワークが必要
  config.vm.network "private_network", type: "dhcp"

  # Rails サーバーの Port 転送
  config.vm.network "forwarded_port", guest: 3000, host: 3000

  # ubuntu
  config.vm.box = "ubuntu/trusty64"

  # LC_ALL の設定が何故かうまく言っていなかったので追加。
  # en_US.UTF-8 にしているので注意
  config.vm.provision :shell, path: "#{SCRIPT_BASE_DIR}/etc/add_LC_ALL_to_locale.sh"

  # ここは NFS を使う。でなければ rails のパフォーマンスは大きく落ちる
  config.vm.synced_folder "./shared", "#{SYNCED_FOLDER_BASE_DIR}", type: "nfs"

  # git のインストール
  config.vm.provision :shell do |s|
    s.name = "GIT"
    s.path = "#{SCRIPT_BASE_DIR}/git/install.sh"
  end
  # この 2 ファイルがホームディレクトリに無いとエラーが出る
  # 必須というわけでは無いので使わなければこの2行をコメントアウトしても良い
  config.vm.provision :file, source: "~/.gitconfig", destination: ".gitconfig"
  config.vm.provision :file, source: "~/.gitignore", destination: ".gitignore"

  # mysql のインストール
  config.vm.provision :shell do |s|
    s.name = "MYSQL"
    s.path = "#{SCRIPT_BASE_DIR}/mysql/install.sh"
  end

  # rbenv のインストール
  config.vm.provision "shell" do |s|
    s.name = "RBENV"
    s.path = "#{SCRIPT_BASE_DIR}/rbenv/install_libraries.sh"
  end
  config.vm.provision "shell" do |s|
    s.name = "RBENV"
    s.path = "#{SCRIPT_BASE_DIR}/rbenv/install.sh"
    s.privileged = false
  end

  # rbenv を使って ruby 2.2.3 のインストール
  config.vm.provision "shell" do |s|
    s.name = "RUBY"
    s.path = "#{SCRIPT_BASE_DIR}/rbenv/install_ruby.sh"
    s.privileged = false
    s.args = "#{RB_VERSION}"
  end

  # bundler のインストール
  config.vm.provision "shell" do |s|
    s.name = "BUNDLER"
    s.path = "#{SCRIPT_BASE_DIR}/rbenv/install_bundler.sh"
    s.privileged = false
    s.args = "#{RB_VERSION}"
  end
end
```

- LC_ALL がうまく設定できなかったので、`scripts/etc/add_LC_ALL_to_locale.sh` で直接指定。`en_US.UTF-8` にしているが環境によって書き換えるべし

# 実行
ホストOS の `${HOGE_ROOT}` ディレクトリ上で下記を実行

```bash
$ vagrant up
```

- `nfs` による共有フォルダ設定の際に ホストOS でのユーザーパスワードを聞かれる
- ruby-2.2.3 のインストールは僕の環境ではかなり時間がかかった。

# もうひとひねり
本当は、案件固有の リポジトリを `git clone` したり、あまつさえ毎起動時に rails server を立ち上げといたりして欲しい。

以下の手順で、Vagrantfile を少し書き換える。

## `scripts/projects/install.sh` を作る
だいたいこんな感じ。案件によって書き換える必要あり。

```bash:scripts/projects/install.sh
#!/bin/bash

# VM 作成時には known_hosts に何も登録されていないので、
# このまま git clone しようとすると失敗する。
# ssh-keyscan を使って、リポジトリのあるドメインの公開鍵を取得する。
ssh-keyscan github.com > known_hosts

mkdir -p /shared/projects
cd /shared/projects
git clone git@github.com:hogehoge/fugafuga.git

cd fugafuga
bundle install --path vendor/bundle --without production --binstubs=bundle_bin
rails rehash

bundle exec rake db:create
bundle exec rake db:migrate
```

## `scripts/projects/start.sh`

```bash:scripts/projects/start.sh
#!/bin/bash

cd /shared/projects/fugafuga
rails server -b 0.0.0.0 -d
```

## `Vagrantfile`
先の Vagrantfile に下記を追記

```ruby:Vagrantfile
Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  # ...

  # bundler のインストール
  config.vm.provision "shell" do |s|
    # ...
  end

  # 案件ごとの設定
  config.vm.provision "shell" do |s|
    s.name = "PROJCET"
    s.path = "#{SCRIPT_BASE_DIR}/project/install.sh"
    s.privileged = false
  end
  # run: "always" によって、VM 構築時だけではなく `vagrant up` するたびに実行される
  config.vm.provision "shell", run: "always" do |s|
    s.name = "PROJECT"
    s.path = "#{SCRIPT_BASE_DIR}/project/start.sh"
    s.privileged = false
  end
end
```

## `.gitignore`
間違えて案件の機密情報をこのリポジトリにコミットしないように、`.gitignore` も更新しておく。

```bash:.gitignore
.vagrant
shared/projects
scripts/projects
```

# パッケージ化しないの？
`vagrant package` の使い方、効用について未調査なのと、`~/.gitconfig` とかに個人のメールアドレスとかが入っていたりするのでおいそれとはパッケージ化しづらい。理想は `vagrant init my_box` からの `vagrant up` だけでその辺の環境変数とかも外から持ってきてくれるようにしたい。

# github
以上のファイル群（案件ごとの設定は含まない）を github リポジトリにして公開しているのでよろしければテンプレートとしてご利用ください。

