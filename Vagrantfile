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
