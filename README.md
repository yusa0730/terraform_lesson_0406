### ローカル環境構築方法

- `/terraform_lesson_0406/environments/dev/src` にて以下のコマンドを実行する。

```
docker build -t docker-nginx .
docker run --name nginx-test --rm -d -p 80:80 docker-nginx
```
