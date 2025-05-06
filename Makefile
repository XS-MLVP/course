.PHONY: init release preview

# 初始化环境
init:
	curl -sL https://deb.nodesource.com/setup_20.x | sudo -E bash -
	sudo apt-get install -y nodejs
	sudo apt remove hugo
	sudo pip3 install hugo==0.145.0
	sudo add-apt-repository ppa:longsleep/golang-backports
	sudo apt update
	sudo apt install golang-go
	npm install -D autoprefixer
	npm install -D postcss-cli
	npm install -D postcss

# 编译并发布网站
release:
	hugo --minify --baseURL $(url)

# 预览网站
preview:
	hugo server -p 8080
